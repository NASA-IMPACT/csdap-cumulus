aws_region = "<%= expansion(':REGION') %>"

#-------------------------------------------------------------------------------
# IMPORTANT
#-------------------------------------------------------------------------------
# The argument to the `expansion` function is duplicated in `Dockerfile` as the
# value of the `CUMULUS_PREFIX` environment variable.  If you change the value
# here, you must also make the corresponding change there.
prefix = "<%= expansion('cumulus-:ENV') %>"
#-------------------------------------------------------------------------------
