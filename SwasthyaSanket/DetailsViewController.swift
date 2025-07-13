import UIKit
import FirebaseFirestore

final class DetailsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var enterDetails: UILabel!
    @IBOutlet private weak var phoneNumber: UITextField!
    @IBOutlet private weak var userName: UITextField!
    @IBOutlet private weak var errorCode: UILabel!
    @IBOutlet private weak var loadingView: UIView!

    // MARK: - Properties
    private var queryListener: ListenerRegistration?
    private var hasNavigated   = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        typewriter(text: "Enter Details", on: enterDetails)

        // ⬇️  Dismiss keyboard on outside tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false      // keep buttons & cells tappable
        view.addGestureRecognizer(tap)

        loadingView.isHidden = true
        errorCode.isHidden   = true

    }
    
    /// Called by the tap‑gesture
    @objc private func endEditing() {
        view.endEditing(true)
    }

    deinit {          // clean up
        queryListener?.remove()
    }

    // MARK: - Actions
    @IBAction private func searchButton(_ sender: UIButton) {
        print("🔍 Search tapped")

        let name  = userName.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = phoneNumber.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty, !phone.isEmpty else {
            showError("Please enter both name and phone number.")
            return
        }

        // reset state
        hasNavigated = false
        queryListener?.remove()

        errorCode.isHidden   = true
        loadingView.isHidden = false

        let db = Firestore.firestore()
        let query = db.collection("workerDetails")
                      .whereField("name",  isEqualTo: name)
                      .whereField("phone", isEqualTo: phone)

        queryListener = query.addSnapshotListener { [weak self] snap, err in
            guard let self = self else { return }
            self.loadingView.isHidden = true

            if let err = err {
                self.showError("Server error: \(err.localizedDescription)")
                return
            }

            guard let docs = snap?.documents, !docs.isEmpty else {
                self.showError("No worker found with those details.")
                return
            }

            self.errorCode.isHidden = true
            docs.forEach { self.handleMatch($0) }

            // Navigate only once
            if !self.hasNavigated, let first = docs.first {
                self.hasNavigated = true
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "xyz", sender: first)
                }
            }
        }
    }

    // MARK: - (Optional) Debug log
    private func handleMatch(_ doc: QueryDocumentSnapshot) {
        print("✅ Found / updated document \(doc.documentID)")
    }

    // MARK: - Typewriter
    private func typewriter(text: String, on label: UILabel, completion: (() -> Void)? = nil) {
        label.text = ""
        label.alpha = 0.1

        let chars = Array(text)
        let totalChars = chars.count

        for i in chars.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                label.text? += String(chars[i])
                
                // Update alpha proportionally as text grows
                let progress = CGFloat(i + 1) / CGFloat(totalChars)
                label.alpha = 0.1 + 0.9 * progress  // fade from 0.1 → 1.0
                
                if i == totalChars - 1 {
                    completion?()
                }
            }
        }
    }



    private func showError(_ message: String) {
        errorCode.text     = message
        errorCode.isHidden = false
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "xyz",
              let dest = segue.destination as? FinalViewController,
              let doc  = sender as? QueryDocumentSnapshot else { return }

        dest.userDocID = doc.documentID
        dest.name      = doc.get("name") as? String

        if let inputs = doc.get("patient_inputs") as? [String: Any] {
            if let ageNumber = inputs["age"] as? NSNumber {
                dest.age = ageNumber.intValue
            } else if let ageInt = inputs["age"] as? Int {
                dest.age = ageInt
            }

            if let bmiNum = inputs["bmi"] as? NSNumber {
                dest.bmi = bmiNum.doubleValue
            } else if let bmiString = inputs["bmi"] as? String,
                      let bmiDouble = Double(bmiString) {
                dest.bmi = bmiDouble
            }
        }

        if let ts = doc.get("timestamp") as? Timestamp {
            dest.createdAt = ts.dateValue()
        } else if let tsString = doc.get("timestamp") as? String {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dest.createdAt = df.date(from: tsString)
        }
    }
}
