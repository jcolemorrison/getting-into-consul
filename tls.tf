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