// Test script to verify competition access control logic
// This can be run in a Dart console or added to your test suite

import 'package:church/core/utils/classes_mapping.dart';

void main() {
  print('=== Competition Access Control Tests ===\n');

  // Test 1: Exact match
  testAccess('1', '1', true, 'Test 1: Exact class match');

  // Test 2: Combined class - user in first class
  testAccess('1', '1&2', true, 'Test 2: User class 1, competition for 1&2');

  // Test 3: Combined class - user in second class
  testAccess('2', '1&2', true, 'Test 3: User class 2, competition for 1&2');

  // Test 4: User has combined class, competition for specific
  testAccess('1&2', '1', true, 'Test 4: User class 1&2, competition for 1');

  // Test 5: No match
  testAccess('1', '3&4', false, 'Test 5: User class 1, competition for 3&4');

  // Test 6: Universal access
  testAccess('1', 'all', true, 'Test 6: Any user, competition for all');
  testAccess('prep1', 'all', true, 'Test 7: Prep student, competition for all');

  // Test 8: Category - primary
  testAccess('3', 'primary', true, 'Test 8: Class 3, competition for primary');

  // Test 9: Category - wrong category
  testAccess('prep1', 'primary', false, 'Test 9: Prep student, competition for primary');

  // Test 10: Category - children includes primary and prep
  testAccess('5', 'children', true, 'Test 10: Class 5, competition for children');
  testAccess('prep2', 'children', true, 'Test 11: Prep 2, competition for children');

  // Test 12: Secondary students
  testAccess('sec1', 'sec', true, 'Test 12: Sec 1, competition for sec category');
  testAccess('sec2', 'youth', true, 'Test 13: Sec 2, competition for youth');

  // Test 14: Wrong category
  testAccess('sec1', 'primary', false, 'Test 14: Secondary student, competition for primary');

  // Test 15: Servants
  testAccess('servants', 'servants', true, 'Test 15: Servant, competition for servants');
  testAccess('1', 'servants', false, 'Test 16: Class 1, competition for servants');

  print('\n=== All Tests Complete ===');
}

void testAccess(String userClass, String targetAudience, bool expected, String description) {
  final result = CompetitionClassMapping.canAccessCompetition(userClass, targetAudience);
  final status = result == expected ? '✅ PASS' : '❌ FAIL';
  final className = CompetitionClassMapping.getClassName(userClass);
  final targetName = CompetitionClassMapping.getClassName(targetAudience);

  print('$status - $description');
  print('   User: $className ($userClass) | Target: $targetName ($targetAudience)');
  print('   Expected: $expected | Got: $result');

  if (result != expected) {
    print('   ⚠️  TEST FAILED!');
  }
  print('');
}

