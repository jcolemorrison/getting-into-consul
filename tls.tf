# Root CA
resource "tls_private_key" "ca_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256" # blargh, need better than NIST
}

resource "tls_self_signed_cert" "ca_cert" {
	key_algorithm = tls_private_key.ca_key.algorithm
	private_key_pem = tls_private_key.ca_key.private_key_pem
	is_ca_certificate = true

	subject {
		common_name = "Consul Agent CA"
		organization = "HashiCorp Inc."
	}

	validity_period_hours = 8760

	allowed_uses = [
		"cert_signing",
    "key_encipherment",
    "digital_signature"
	]
}

# Server Certificates
resource "tls_private_key" "server_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256" # blargh, need better than NIST
}

## Public Server Cert
resource "tls_cert_request" "server_cert" {
	key_algorithm = tls_private_key.server_key.algorithm
	private_key_pem = tls_private_key.server_key.private_key_pem

	subject {
		common_name = "server.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"server.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Signed Public Server Certificate
resource "tls_locally_signed_cert" "server_signed_cert" {
	cert_request_pem = tls_cert_request.server_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}

# Client Web Certificates
resource "tls_private_key" "client_web_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

## Public Client Cert
resource "tls_cert_request" "client_web_cert" {
	key_algorithm = tls_private_key.client_web_key.algorithm
	private_key_pem = tls_private_key.client_web_key.private_key_pem

	subject {
		common_name = "client.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"client.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Signed Public Client Certificate
resource "tls_locally_signed_cert" "client_web_signed_cert" {
	cert_request_pem = tls_cert_request.client_web_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}

# Client API Certificates
resource "tls_private_key" "client_api_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

## Public Client Cert
resource "tls_cert_request" "client_api_cert" {
	key_algorithm = tls_private_key.client_api_key.algorithm
	private_key_pem = tls_private_key.client_api_key.private_key_pem

	subject {
		common_name = "client.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"client.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Signed Public Client Certificate
resource "tls_locally_signed_cert" "client_api_signed_cert" {
	cert_request_pem = tls_cert_request.client_api_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}

# Client API v2 Certificates
resource "tls_private_key" "client_api_v2_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

## Public Client Cert
resource "tls_cert_request" "client_api_v2_cert" {
	key_algorithm = tls_private_key.client_api_v2_key.algorithm
	private_key_pem = tls_private_key.client_api_v2_key.private_key_pem

	subject {
		common_name = "client.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"client.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Signed Public Client Certificate
resource "tls_locally_signed_cert" "client_api_v2_signed_cert" {
	cert_request_pem = tls_cert_request.client_api_v2_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}

# Ingress Gateway Certificates
resource "tls_private_key" "ingress_gateway_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

## Ingress Gateway Public Client Cert
resource "tls_cert_request" "ingress_gateway_cert" {
	key_algorithm = tls_private_key.ingress_gateway_key.algorithm
	private_key_pem = tls_private_key.ingress_gateway_key.private_key_pem

	subject {
		common_name = "ingress.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"ingress.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Ingress Gateway Signed Public Client Certificate
resource "tls_locally_signed_cert" "ingress_gateway_signed_cert" {
	cert_request_pem = tls_cert_request.ingress_gateway_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}

# Terminating Gateway Certificates
resource "tls_private_key" "terminating_gateway_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

## Terminating Gateway Public Client Cert
resource "tls_cert_request" "terminating_gateway_cert" {
	key_algorithm = tls_private_key.terminating_gateway_key.algorithm
	private_key_pem = tls_private_key.terminating_gateway_key.private_key_pem

	subject {
		common_name = "terminating.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"terminating.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Terminating Gateway Signed Public Client Certificate
resource "tls_locally_signed_cert" "terminating_gateway_signed_cert" {
	cert_request_pem = tls_cert_request.terminating_gateway_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}

# Database Gateway Certificates
resource "tls_private_key" "database_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

## Database Gateway Public Client Cert
resource "tls_cert_request" "database_cert" {
	key_algorithm = tls_private_key.database_key.algorithm
	private_key_pem = tls_private_key.database_key.private_key_pem

	subject {
		common_name = "database.dc1.consul" # dc1 is the default data center name we used
		organization = "HashiCorp Inc."
	}

	dns_names = [
		"database.dc1.consul",
		"localhost"
	]

	ip_addresses = ["127.0.0.1"]
}

## Database Gateway Signed Public Client Certificate
resource "tls_locally_signed_cert" "database_signed_cert" {
	cert_request_pem = tls_cert_request.database_cert.cert_request_pem

	ca_private_key_pem = tls_private_key.ca_key.private_key_pem
	ca_key_algorithm = tls_private_key.ca_key.algorithm
	ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

	allowed_uses = [
		"digital_signature",
		"key_encipherment"
	]

	validity_period_hours = 8760
}