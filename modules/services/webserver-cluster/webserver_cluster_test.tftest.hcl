variables {
  cluster_name  = "test-cluster"
  instance_type = "t2.micro"
  min_size      = 1
  max_size      = 2
  environment   = "dev"
  project_name  = "30-Day Terraform Challenge"
  team_name     = "Belinda Ntinyari"
}

# -------------------------------------------------------
# Test 1 — ASG name prefix matches cluster_name variable
#
# WHY: If the ASG name prefix does not include the cluster
# name, two deployments with different cluster names would
# produce ASGs with identical names and conflict in AWS.
# -------------------------------------------------------
run "validate_asg_name_prefix" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.this.name_prefix == "test-cluster-asg-"
    error_message = "ASG name_prefix must be '{cluster_name}-asg-' — got unexpected value"
  }
}

# -------------------------------------------------------
# Test 2 — Launch template instance type matches variable
#
# WHY: If the instance type is hardcoded instead of
# referencing the variable, changing var.instance_type
# would have no effect and the wrong instance type would
# be deployed silently.
# -------------------------------------------------------
run "validate_instance_type" {
  command = plan

  assert {
    condition     = aws_launch_template.this.instance_type == "t2.micro"
    error_message = "Launch template instance_type must match var.instance_type — got unexpected value"
  }
}

# -------------------------------------------------------
# Test 3 — ALB security group has exactly one ingress rule
#
# WHY: Extra ingress rules on the ALB security group could
# expose unexpected ports to the internet. This test
# confirms only the expected rule exists.
# -------------------------------------------------------
run "validate_alb_sg_ingress_count" {
  command = plan

  assert {
    condition     = length(aws_security_group.alb.ingress) == 1
    error_message = "ALB security group must have exactly 1 ingress rule"
  }
}

# -------------------------------------------------------
# Test 4 — ALB ingress rule is port 80
#
# WHY: The ALB should accept HTTP traffic on port 80.
# If the port is wrong, no traffic reaches the cluster
# at all.
# -------------------------------------------------------
run "validate_alb_sg_port" {
  command = plan

  assert {
    condition     = one(aws_security_group.alb.ingress).from_port == 80
    error_message = "ALB security group must allow inbound traffic on port 80"
  }
}

# -------------------------------------------------------
# Test 5 — ASG min_size matches variable
#
# WHY: If min_size is hardcoded, the production calling
# config cannot increase the floor count and the cluster
# may be under-provisioned.
# -------------------------------------------------------
run "validate_asg_min_size" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.this.min_size == 1
    error_message = "ASG min_size must match var.min_size"
  }
}

# -------------------------------------------------------
# Test 6 — ASG max_size matches variable
# -------------------------------------------------------
run "validate_asg_max_size" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.this.max_size == 2
    error_message = "ASG max_size must match var.max_size"
  }
}

# -------------------------------------------------------
# Test 7 — ASG health check type is ELB, not EC2
#
# WHY: This is the most critical correctness check.
# EC2 health checks only detect crashed VMs.
# ELB health checks detect failed application processes.
# A cluster using EC2 health checks will never replace
# an instance whose app has crashed but VM is still up.
# -------------------------------------------------------
run "validate_health_check_type" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "ELB"
    error_message = "ASG health_check_type must be ELB — EC2 health checks do not detect application failures"
  }
}

# -------------------------------------------------------
# Test 8 — Environment tag is propagated to ASG instances
#
# WHY: The environment tag is used for cost allocation
# and compliance filtering. If it is missing from the
# propagated tags, EC2 instances will be untagged even
# though the ASG itself is tagged.
# -------------------------------------------------------
run "validate_environment_tag" {
  command = plan

  assert {
    condition = anytrue([
      for tag in aws_autoscaling_group.this.tag :
      tag.key == "Environment" && tag.value == "dev" && tag.propagate_at_launch == true
    ])
    error_message = "ASG must propagate an Environment tag with the correct value to launched instances"
  }
}

# -------------------------------------------------------
# Test 9 — Invalid environment value is rejected
#
# WHY: The validation block in variables.tf should catch
# invalid environment values at plan time. This test
# confirms the validation rule is working.
# -------------------------------------------------------
run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "production-staging"
  }

  expect_failures = [
    var.environment,
  ]
}

# -------------------------------------------------------
# Test 10 — Invalid instance type is rejected
#
# WHY: The regex validation should reject non-t2/t3 types.
# This confirms the validation rule is in place.
# -------------------------------------------------------
run "reject_invalid_instance_type" {
  command = plan

  variables {
    instance_type = "m5.large"
  }

  expect_failures = [
    var.instance_type,
  ]
}
