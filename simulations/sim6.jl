

# Scenario 1


p_a_given_z = .9
p_a_given_not_z = .01
p_z = .5
p_a = p_a_given_z * p_z + p_a_given_not_z * (1 - p_z)

p_z_given_cB = .99
p_b_given_cB = p_z_given_cB = .99

p_a_given_cB = p_a_given_z * p_z_given_cB + p_a_given_not_z * (1 - p_z_given_cB)


p_z_given_not_cC = p_z_given_cB = .99
p_b_given_not_cC = p_z_given_not_cC

p_z_given_cC = .5
p_b_given_cC = p_z_given_cC

p_a_given_cC = p_a_given_z * p_z_given_cC + p_a_given_not_z * (1 - p_z_given_cC)

support = p_b_given_cC / p_b_given_not_cC

p_a_given_cC = p_a + support * (p_a_given_cB - p_a)


# Scenario 2

	# P(B|not cC) = 0.01
	# P(B|cC) = .99


p_a_given_z = .9
p_a_given_not_z = .01
p_z = .5
p_a = p_a_given_z * p_z + p_a_given_not_z * (1 - p_z)

p_z_given_cB = .01
p_b_given_cB = p_z_given_cB

p_a_given_cB = p_a_given_z * p_z_given_cB + p_a_given_not_z * (1 - p_z_given_cB)

p_z_given_not_cC = p_z_given_cB = .01
p_b_given_not_cC = p_z_given_not_cC

alpha = .5

p_z_given_cC = .99
p_b_given_cC = p_z_given_cC * alpha

p_a_given_cC = p_a_given_z * p_z_given_cC + p_a_given_not_z * (1 - p_z_given_cC)

#support = p_b_given_cC / p_b_given_not_cC
#p_a_given_cC = p_a + support * (p_a_given_cB - p_a)


p_a_given_cC_approx = p_a_given_z * p_b_given_cC/alpha + p_a_given_not_z * (1 - p_b_given_cC/alpha)


