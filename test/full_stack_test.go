// End-to-end test: deploys multiple modules in dependency

package test

import (
	"fmt"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestFullStackEndToEnd(t *testing.T) {
	t.Parallel()

	// One unique ID shared across all modules in this test.
	// This ties all resources together so you can identify everything belonging to this specific test run.
	uniqueID := random.UniqueId()

	// Step 1 — Deploy the webserver cluster
	// In a full stack test this would first deploy VPC, then pass VPC outputs into the app module.
	// Here we use the default VPC to keep the test self-contained without a separate VPC module.
	appOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/services/webserver-cluster",
		Vars: map[string]interface{}{
			"cluster_name":  fmt.Sprintf("e2e-test-%s", uniqueID),
			"instance_type": "t2.micro",
			"min_size":      1,
			"max_size":      2,
			"environment":   "dev",
			"project_name":  "30-Day Terraform Challenge",
			"team_name":     "Belinda Ntinyari",
		},
	})

	// defer ensures destroy runs even if assertions fail.
	defer terraform.Destroy(t, appOptions)
	terraform.InitAndApply(t, appOptions)

	// Step 2 — Assert outputs are correct
	albDnsName := terraform.Output(t, appOptions, "alb_dns_name")
	albUrl := terraform.Output(t, appOptions, "alb_url")
	asgName := terraform.Output(t, appOptions, "asg_name")

	assert.NotEmpty(t, albDnsName, "ALB DNS name must not be empty")
	assert.NotEmpty(t, albUrl, "ALB URL must not be empty")
	assert.NotEmpty(t, asgName, "ASG name must not be empty")
	assert.Contains(t, asgName, fmt.Sprintf("e2e-test-%s", uniqueID),
		"ASG name must contain the cluster name")

	// Step 3 — Verify end-to-end HTTP path
	// This is the core of the end-to-end test.
	url := fmt.Sprintf("http://%s", albDnsName)

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		// Retry up to 30 times (30 * 10s = 5 minutes max)
		// Long enough for instances to pass health checks
		30,
		10*time.Second,
		func(status int, body string) bool {
			// Assert: HTTP 200 and body contains expected content
			if status != 200 {
				return false
			}
			// The web server should return non-empty HTML
			if len(body) == 0 {
				return false
			}
			return true
		},
	)
}