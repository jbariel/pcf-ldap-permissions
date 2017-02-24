#!/bin/sh

HELP_REGEX="^-+[hH].*"

if [[ $1 =~ $HELP_REGEX ]]; then
    echo "How to use $0..."
    echo "    $0 <username> [Admin|Deploy|ReadOnly]"
    echo " "
    echo "    username: username to modify permissions on"
    echo "    role: one of the given roles, this is case-sensitive!!!"
    echo " "
    echo " "
    exit 0;
fi

# This is the main 
CF_SYSTEM_DOMAIN=
if [ -z "$CF_SYSTEM_DOMAIN" ]; then
    echo "Must configure a CF_SYSTEM_DOMAIN inside of the script"
    exit 1
fi
UAAC_TARGET=uaa.$CF_SYSTEM_DOMAIN
CF_TARGET=api.$CF_SYSTEM_DOMAIN

# use for self-signed certs
SKIP_SSL="--skip-ssl-validation"
# use for valid certs
#SKIP_SSL=

# uaac admin client credentials
UAAC_ADMIN_UN=admin
UAAC_ADMIN_PW=
if [ -z "$UAAC_ADMIN_PW" ]; then
    echo "Must configure a UAAC_ADMIN_PW inside of the script.  This is the UAA admin client password"
    exit 1
fi

# CF CLI Admin credentials
CF_ADMIN=admin
CF_PASSWORD=
if [ -z "$CF_PASSWORD" ]; then
    echo "Must configure a CF_PASSWORD inside of the script.  This is the CF CLI admin password"
    exit 1
fi

# User to modify
TMP_USER=$1
if [ -z "$TMP_USER" ]; then
    echo "Must provide a username as the first arg!"
    exit 1
else
    echo "Configuring user '$TMP_USER'..."
fi

UAAC_PERMS=
CF_ORG_PERM=
CF_SPACE_PERM=

# Role to set
ROLE=$2
if [ -z "$ROLE" ]; then
    echo "Must provide a role (Admin|Deploy|ReadOnly) as the second arg!"
    exit 1
elif [ "Admin" = "$ROLE" ]; then
    echo "... with the 'Admin' role"
    UAAC_PERMS="cloud_controller.admin"
    CF_ORG_PERM=OrgManager
    CF_SPACE_PERM=SpaceManager
elif [ "Deploy" = "$ROLE" ]; then
    echo "... with the 'Deploy' role"
    UAAC_PERMS="cloud_controller.write"
    CF_ORG_PERM=OrgAuditor
    CF_SPACE_PERM=SpaceDeveloper
elif [ "ReadOnly" = "$ROLE" ]; then
    echo "... with the 'ReadOnly' role"
    UAAC_PERMS="cloud_controller.read"
    CF_ORG_PERM=OrgAuditor
    CF_SPACE_PERM=SpaceAuditor
else
    echo "Could not understand what '$ROLE' was, please enter one of: Admin | Deploy | ReadOnly"
    exit 1
fi

#############################################
# Login to UAAC
#############################################
uaac target $UAAC_TARGET $SKIP_SSL
uaac token client get $UAAC_ADMIN_UN -s $UAAC_ADMIN_PW

#############################################
# Set permissions in UAAC
#############################################
for R in admin write read; do
    uaac member delete cloud_controller.$R $TMP_USER
done
uaac member add $UAAC_PERMS $TMP_USER

#############################################
# Login to CF CLI
#############################################
cf login -a $CF_TARGET -u $CF_ADMIN -p $CF_PASSWORD -o system -s system $SKIP_SSL

#############################################
# Set permissions in CF CLI
#############################################
for I in $(cf orgs | awk 'NR>3 {print $0;}'); do 
    for R in OrgManager OrgAuditor OrgBillingManager; do
        cf unset-org-role $TMP_USER $I $R
    done
    cf set-org-role $TMP_USER $I $CF_ORG_PERM; 
    cf target -o $I; 
    for J in $(cf spaces | awk 'NR>3 {print $0;}'); do
        for R in SpaceManager SpaceDeveloper SpaceAuditor; do
            cf unset-space-role $TMP_USER $I $J $R
        done
        cf set-space-role $TMP_USER $I $J $CF_SPACE_PERM; 
    done; 
done

exit 0
