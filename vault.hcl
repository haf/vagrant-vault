backend "consul" {
  address = "127.0.0.1:8500"
  path = "vault"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_key_file = "/etc/pki/tls/private/vault.key"
  tls_cert_file = "/etc/pki/tls/private/vault.crt"
}