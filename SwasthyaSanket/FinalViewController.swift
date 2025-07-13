import UIKit
import FirebaseFirestore

final class FinalViewController: UIViewController {
    
    
    @IBOutlet weak var cityName: UILabel!
    
    
    @IBOutlet weak var doctorNames: UILabel!
    
    
    
    
    
    
    
    
    
    
    
    
    
    @IBOutlet weak var kidneyDiseaseText: UILabel!
    @IBOutlet weak var copdText: UILabel!
    @IBOutlet weak var heartDiseaseText: UILabel!
    
    
    @IBOutlet weak var hypertensionText: UILabel!
    
    
    @IBOutlet weak var hypertensionProgress: UIProgressView!
    
    
    @IBOutlet weak var diabetesText: UILabel!
    
    
    @IBOutlet weak var diabetesProgress: UIProgressView!
    
    
    
    @IBOutlet weak var heartDiseaseProgress: UIProgressView!
    
    
    
    @IBOutlet weak var copdProgress: UIProgressView!
    
    
    @IBOutlet weak var kidneyDiseaseProgress: UIProgressView!
    
    
    
    
    
    
    
    
    
    private var dietListener: ListenerRegistration?
    private var task1Listener: ListenerRegistration?
    private var task2Listener: ListenerRegistration?
    private var basicListener: ListenerRegistration?



    // IBOutlets
    @IBOutlet private weak var patientName: UILabel!
    @IBOutlet private weak var patientBMI:  UILabel!
    @IBOutlet private weak var patientAge:  UILabel!
    @IBOutlet private weak var creationDate: UILabel!

    @IBOutlet private weak var dietPlan: UILabel!
    @IBOutlet private weak var task1: UILabel!
    @IBOutlet private weak var task2: UILabel!

    // Data from DetailsViewController
    var name: String?
    var bmi:  Double?
    var age:  Int?
    var createdAt: Date?
    var userDocID: String!          // ← NEW
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenToBasicFields()
        listenToDietPlan()
        listenToWorkTasks()
        listenToDiseaseProbs()
        fetchDoctorRecommendations()

    }


    override func viewDidLoad() {
        super.viewDidLoad()
        configureStaticFields()
        listenToBasicFields()
        listenToDietPlan()
        fetchDoctorRecommendations()
        listenToWorkTasks()
        listenToDiseaseProbs()  // ← Make sure this is added
        print("▶️ FinalVC loaded with userDocID =", userDocID ?? "nil")
    }


    deinit {
        basicListener?.remove()
        dietListener?.remove()
        task1Listener?.remove()
        task2Listener?.remove()
    }


    // MARK: - Static fields we already had
    private func configureStaticFields() {
        patientName.text = name ?? "—"

        if let bmi = bmi {
            patientBMI.numberOfLines = 0
            patientBMI.text = "BMI:\n" + String(format: "%.1f", bmi)
        } else { patientBMI.text = "BMI:\n—" }

        if let age = age {
            patientAge.numberOfLines = 0
            patientAge.text = "Age:\n\(age)"
        } else { patientAge.text = "Age:\n—" }

        if let d = createdAt {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            creationDate.text = "Creation Date:\n" + fmt.string(from: d)
        } else { creationDate.text = "Creation Date:\n—" }
    }

    // 🔸 Diet Plan + Status  — live listener
    private func listenToDietPlan() {
        let db = Firestore.firestore()
        dietListener = db.collection("workerDetails")
            .document(userDocID)
            .collection("diet")
            .document("plan")
            .addSnapshotListener { [weak self] snap, err in
                DispatchQueue.main.async {                        // ← NEW
                    guard let self = self else { return }
                    if let err = err {
                        self.dietPlan.text = "Diet error: \(err.localizedDescription)"
                        return
                    }
                    guard let doc = snap, doc.exists else {
                        self.dietPlan.text = "No diet plan"
                        return
                    }
                    let recs   = doc.get("recommendations") as? [String] ?? []
                    let status = doc.get("status") as? String ?? "—"
                    self.dietPlan.numberOfLines = 0
                    self.dietPlan.text =
                        (recs.isEmpty ? "No recommendations" : recs.joined(separator: "\n"))
                        + "\n\nStatus: \(status)"
                }
            }

    }


    // 🔸 Work Tasks  — live listeners for both docs
    private func listenToWorkTasks() {
        let db = Firestore.firestore()
        let base = db.collection("workerDetails")
                     .document(userDocID)
                     .collection("workPlan")

        task1Listener = base.document("task_01")
            .addSnapshotListener { [weak self] snap, err in
                self?.updateTaskLabel(label: self?.task1, docID: "task_01", doc: snap, err: err)
            }

        task2Listener = base.document("task_02")
            .addSnapshotListener { [weak self] snap, err in
                self?.updateTaskLabel(label: self?.task2, docID: "task_02", doc: snap, err: err)
            }
    }

    /// shared formatter
    private func updateTaskLabel(label: UILabel?,
                                 docID: String,
                                 doc snap: DocumentSnapshot?,
                                 err: Error?) {
        DispatchQueue.main.async {                            // ← NEW
            guard let label = label else { return }
            if let err = err {
                label.text = "\(docID) error: \(err.localizedDescription)"
                return
            }
            guard let doc = snap, doc.exists else {
                label.text = "No \(docID) data"
                return
            }
            let t = doc.get("task")     as? String ?? "—"
            let p = doc.get("priority") as? String ?? "—"
            let d = doc.get("duration") as? String ?? "—"
            label.numberOfLines = 0
            label.text = "\(t)  (\(p), \(d))"
        }
    }


    
    // 🔸 Basic demographic fields (name, age, bmi, timestamp)
    private func listenToBasicFields() {
        let db = Firestore.firestore()
        basicListener = db.collection("workerDetails")
            .document(userDocID)
            .addSnapshotListener { [weak self] snap, err in
                DispatchQueue.main.async {                        // ← NEW
                    guard let self = self else { return }
                    if let err = err { print("Basic fields error:", err); return }
                    guard let doc = snap, doc.exists else { return }

                    self.patientName.text = doc.get("name") as? String ?? "—"
                    if let inputs = doc.get("patient_inputs") as? [String: Any] {
                        if let bmiNum = inputs["bmi"] as? NSNumber {
                            self.patientBMI.text = "BMI:\n" + String(format: "%.1f", bmiNum.doubleValue)
                        } else if let bmiStr = inputs["bmi"] as? String,
                                  let bmiVal = Double(bmiStr) {
                            self.patientBMI.text = "BMI:\n" + String(format: "%.1f", bmiVal)
                        }
                        if let ageNum = inputs["age"] as? NSNumber {
                            self.patientAge.text = "Age:\n\(ageNum.intValue)"
                        } else if let ageInt = inputs["age"] as? Int {
                            self.patientAge.text = "Age:\n\(ageInt)"
                        }
                    }
                    if let ts = doc.get("timestamp") as? Timestamp {
                        self.creationDate.text = "Creation Date:\n" +
                            DateFormatter.mediumShort.string(from: ts.dateValue())
                    } else if let tsStr = doc.get("timestamp") as? String,
                              let date = DateFormatter.isoMicros.date(from: tsStr) {
                        self.creationDate.text = "Date:\n" +
                            DateFormatter.mediumShort.string(from: date)
                    }
                }
            }

    }
    
    
    private func listenToDiseaseProbs() {
        let db = Firestore.firestore()
        let docRef = db.collection("workerDetails").document(userDocID)

        docRef.addSnapshotListener { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let data = snapshot?.data(), error == nil else {
                    print("❌ Error fetching document:", error?.localizedDescription ?? "Unknown")
                    return
                }

                guard let diseaseMap = data["disease_probs"] as? [String: Any] else {
                    print("⚠️ disease_probs map not found")
                    return
                }

                func updateProgressBar(_ progressBar: UIProgressView, value: Float) {
                    progressBar.setProgress(value, animated: true)
                    let percent = value * 100

                    switch percent {
                    case 0..<35:
                        progressBar.progressTintColor = .systemGreen
                    case 35..<70:
                        progressBar.progressTintColor = .systemYellow
                    default:
                        progressBar.progressTintColor = .systemRed
                    }
                }

                if let val = diseaseMap["COPD"] as? NSNumber {
                    let floatVal = val.floatValue
                    updateProgressBar(self.copdProgress, value: floatVal)
                    self.copdText.text = "COPD: \(Int(floatVal * 100))%"
                }
                if let val = diseaseMap["Diabetes"] as? NSNumber {
                    let floatVal = val.floatValue
                    updateProgressBar(self.diabetesProgress, value: floatVal)
                    self.diabetesText.text = "Diabetes: \(Int(floatVal * 100))%"
                }
                if let val = diseaseMap["Heart Disease"] as? NSNumber {
                    let floatVal = val.floatValue
                    updateProgressBar(self.heartDiseaseProgress, value: floatVal)
                    self.heartDiseaseText.text = "Heart Disease: \(Int(floatVal * 100))%"
                }
                if let val = diseaseMap["Hypertension"] as? NSNumber {
                    let floatVal = val.floatValue
                    updateProgressBar(self.hypertensionProgress, value: floatVal)
                    self.hypertensionText.text = "Hypertension: \(Int(floatVal * 100))%"
                }
                if let val = diseaseMap["Kidney Disease"] as? NSNumber {
                    let floatVal = val.floatValue
                    updateProgressBar(self.kidneyDiseaseProgress, value: floatVal)
                    self.kidneyDiseaseText.text = "Kidney Disease: \(Int(floatVal * 100))%"
                }
            }
        }
    }
    
    
    
    private func fetchDoctorRecommendations() {
        let db = Firestore.firestore()
        let docRef = db.collection("workerDetails")
                       .document(userDocID)
                       .collection("doctor")
                       .document("recommendation")

        docRef.addSnapshotListener { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard error == nil, let data = snapshot?.data() else {
                    self.cityName.text = "—"
                    self.doctorNames.text = "—"
                    print("❌ Doctor fetch error:", error?.localizedDescription ?? "Unknown")
                    return
                }

                let city = data["city"] as? String ?? "—"
                var rawInfo = data["info"] as? String ?? ""

                self.cityName.text = city
                self.doctorNames.numberOfLines = 0

                // 🔧 Clean and reformat the info string
                rawInfo = rawInfo.replacingOccurrences(of: #"\\\."#, with: ".", options: .regularExpression)

                // Split the info into parts at "1. ", "2. ", etc.
                let matches = rawInfo.components(separatedBy: #"(?=\d+\.\s)"#)
                                     .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                // Join with newlines
                let formattedInfo = matches.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)

                self.doctorNames.text = formattedInfo
            }
        }
    }









}

fileprivate extension DateFormatter {
    static var mediumShort: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    static var isoMicros: DateFormatter = {
        let f = DateFormatter()
        f.locale = .init(identifier: "en_US_POSIX")
        f.timeZone = .init(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return f
    }()
}

