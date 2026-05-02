import 'patient_model.dart';
import 'als_state.dart';

class Scenario {
  final String id;
  final String title;
  final String dispatchInfo; // Wezwanie z dyspozytorni
  final String sceneSizeUp; // Co widzisz po wejściu (Scene size-up)
  final PatientRhythm initialRhythm;
  final PatientModel Function()
  generatePatient; // Fabryka pacjenta dla tego scenariusza

  Scenario({
    required this.id,
    required this.title,
    required this.dispatchInfo,
    required this.sceneSizeUp,
    required this.initialRhythm,
    required this.generatePatient,
  });
}
