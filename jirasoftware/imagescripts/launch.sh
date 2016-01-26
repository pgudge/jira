#!/bin/bash
set -o errexit

. ${JIRA_SCRIPTS}/common.bash

rm -f /opt/atlassian-home/.jira-home.lock

if [ "$JIRA_CONTEXT_PATH" == "ROOT" -o -z "$JIRA_CONTEXT_PATH" ]; then
  CONTEXT_PATH=
else
  CONTEXT_PATH="/$JIRA_CONTEXT_PATH"
fi

xmlstarlet ed -P -S -L -u '//Context/@path' -v "$CONTEXT_PATH" ${JIRA_INSTALL}/conf/server.xml

if [ -n "$DATABASE_URL" ]; then
  extract_database_url "$DATABASE_URL" DB ${JIRA_INSTALL}/lib
  DB_JDBC_URL="$(xmlstarlet esc "$DB_JDBC_URL")"
  SCHEMA=''
  if [ "$DB_TYPE" != "mysql" ]; then
    SCHEMA='<schema-name>public</schema-name>'
  fi

  cat <<END > ${JIRA_HOME}/dbconfig.xml
<?xml version="1.0" encoding="UTF-8"?>
<jira-database-config>
  <name>defaultDS</name>
  <delegator-name>default</delegator-name>
  <database-type>$DB_TYPE</database-type>
  $SCHEMA
  <jdbc-datasource>
    <url>$DB_JDBC_URL</url>
    <driver-class>$DB_JDBC_DRIVER</driver-class>
    <username>$DB_USER</username>
    <password>$DB_PASSWORD</password>
    <pool-min-size>20</pool-min-size>
    <pool-max-size>20</pool-max-size>
    <pool-max-wait>30000</pool-max-wait>
    <pool-max-idle>20</pool-max-idle>
    <pool-remove-abandoned>true</pool-remove-abandoned>
    <pool-remove-abandoned-timeout>300</pool-remove-abandoned-timeout>
  </jdbc-datasource>
</jira-database-config>
END
fi
