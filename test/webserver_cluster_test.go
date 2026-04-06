// Integration test using Terratest.

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

func TestWebserverClusterIntegration(t *testing.T) {
	// t.Parallel() allows multiple test functions to run simultaneously rather than sequentially.
	t.Parallel()

	// Generate a unique ID for this test run.
	// This prevents name conflicts if two tests run at  the same time, and makes it easy to identify which AWS resources belong to which test run.
	uniqueID := random.UniqueId()
	clusterName := fmt.Sprintf("test-cluster-%s", uniqueID)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/services/webserver-cluster",
		Vars: map[string]interface{}{
			"cluster_name":  clusterName,
			"instance_type": "t2.micro",
			"min_size":      1,
			"max_size":      2,
			"environment":   "dev",
			"project_name":  "30-Day Terraform Challenge",
			"team_name":     "Belinda Ntinyari",
		},
	})

	// defer runs when the test function exits whether  the test passes, fails, or panics. 
	// This guarantees terraform destroy runs no matter what happens.
	// Without this, a mid-test failure would leave real AWS resources running and charging money.
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init followed by terraform apply.
	// The test will fail immediately if apply fails.
	terraform.InitAndApply(t, terraformOptions)

	// Read the ALB DNS name from the terraform outputs —
	// same value you would get from terraform output
	// alb_dns_name after a manual deployment.
	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	// Assert the output exists and is not empty.
	// An empty ALB DNS name means the output block is
	// missing or the ALB was not created.
	assert.NotEmpty(t, albDnsName, "ALB DNS name output should not be empty after apply")

	// The validation function checks two things:
	// 1. HTTP status code is 200
	// 2. The response body is non-empty
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		30,
		10*time.Second,
		func(status int, body string) bool {
			return status == 200 && len(body) > 0
		},
	)
}

// TestWebserverClusterOutputs verifies that all expected outputs are defined and non-empty after apply.
func TestWebserverClusterOutputs(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/services/webserver-cluster",
		Vars: map[string]interface{}{
			"cluster_name":  fmt.Sprintf("test-outputs-%s", uniqueID),
			"instance_type": "t2.micro",
			"min_size":      1,
			"max_size":      2,
			"environment":   "dev",
			"project_name":  "30-Day Terraform Challenge",
			"team_name":     "Belinda Ntinyari",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify each expected output is present and non-empty
	outputs := []string{
		"alb_dns_name",
		"alb_url",
		"asg_name",
	}

	for _, outputName := range outputs {
		value := terraform.Output(t, terraformOptions, outputName)
		assert.NotEmpty(t, value,
			fmt.Sprintf("Output '%s' should not be empty after apply", outputName))
	}
}