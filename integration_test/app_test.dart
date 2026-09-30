import 'package:integration_test/integration_test.dart';
import 'auth_flow_test.dart';
import 'planner_flow_test.dart';
import 'side_tasks_and_notes_flow_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run all Level 3 E2E Integration flows
  runAuthFlowTests();
  runPlannerFlowTests();
  runSideTasksAndNotesFlowTests();
}
