# Copy of the Harness runtime policy steelthread_lkg_promotion, for readers.
# The live copy is in Harness (policy set steelthread_lkg_promotion).
# The LKG gate (stage lkg_gate) evaluates this policy against evidence.json.
package steelthread

deny[msg] {
  input.tests.failed_not_quarantined > 0
  msg := sprintf("%d failing tests are not quarantined", [input.tests.failed_not_quarantined])
}

deny[msg] {
  role := ["qe", "product", "compliance"][_]
  not input.approvals[role]
  msg := sprintf("missing %s sign-off", [role])
}

deny[msg] {
  input.hazard_analysis_closed != true
  msg := "software hazard analysis ticket is not closed"
}

deny[msg] {
  input.env_release != "clean"
  input.env_release != "dirty"
  msg := "environment was not released"
}
