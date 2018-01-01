###############################################################################
## SSL Certificate and key paths
ssl_cert = {
   cert = "ssl/rajrao.gcp.arc-ts.umich.edu.cert"
   key = "ssl/rajrao.gcp.arc-ts.umich.edu.key"
}

###############################################################################
## DNS Settings
enable_dns = false
dns_zone = "gcp-arcts-zone"
dns_name = "brockp.gcp.arc-ts.umich.edu."


###############################################################################
## Globus OAuth Settings
#
# Callback needs to match that in the globus config
# client_id and secrete are from globus.org
globus_oauth = {
    callback_url  = "https://brockp.gcp.arc-ts.umich.edu/hub/oauth_callback"
    client_id     = "<CLIENTID>"
    client_secret = "<CLIENT SECRET>"
    identity_provider = "umich.edu"
}
