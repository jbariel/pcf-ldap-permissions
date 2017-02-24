# PCF Role set for LDAP integration
Technically not specific to LDAP, could be used for SSO.  Tools to manage permissions.

## updatePerms.sh
Takes a given username and sets the permissions to fit one of 3 roles:
* Admin - admin for the cloud controller, manager for all orgs/spaces
* Deploy - write for the cloud controller, auditor for all orgs and developer for all spaces
* ReadOnly - read for the cloud contorller, auditor for all orgs/spaces

### First steps
You will need to set 3 variables inside the script:

* `CF_SYSTEM_DOMAIN` => The System domain set in OpsManager Director
* `UAAC_ADMIN_PW` => This is the UAA Admin client credentials
* `CF_PASSWORD` => This is the admin credentials for the CF CLI

Also verify the following:

* `UAAC_TARGET=uaa.$CF_SYSTEM_DOMAIN`
* `CF_TARGET=api.$CF_SYSTEM_DOMAIN`
* `SKIP_SSL="--skip-ssl-validation"` (set to `""` to validate SSL (use for self-signed certs)
* `UAAC_ADMIN_UN=admin`
* `CF_ADMIN=admin`

### Clone and run
Simply clone the project, then you can run it.

`./updatePerms.sh <username> <role>`

# Issues
Please use the [Issues tab](../../issues) to report any problems or feature requests.
