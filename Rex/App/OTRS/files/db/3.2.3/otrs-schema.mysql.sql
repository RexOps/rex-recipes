# ----------------------------------------------------------
#  driver: mysql, generated: 2012-11-07 17:21:16
# ----------------------------------------------------------
# ----------------------------------------------------------
#  create table valid
# ----------------------------------------------------------
CREATE TABLE valid (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX valid_name (name)
);
# ----------------------------------------------------------
#  create table users
# ----------------------------------------------------------
CREATE TABLE users (
    id INTEGER NOT NULL AUTO_INCREMENT,
    login VARCHAR (200) NOT NULL,
    pw VARCHAR (64) NOT NULL,
    title VARCHAR (50) NULL,
    first_name VARCHAR (100) NOT NULL,
    last_name VARCHAR (100) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX users_login (login)
);
# ----------------------------------------------------------
#  create table user_preferences
# ----------------------------------------------------------
CREATE TABLE user_preferences (
    user_id INTEGER NOT NULL,
    preferences_key VARCHAR (150) NOT NULL,
    preferences_value VARCHAR (250) NULL,
    INDEX user_preferences_user_id (user_id)
);
# ----------------------------------------------------------
#  create table groups
# ----------------------------------------------------------
CREATE TABLE groups (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX groups_name (name)
);
# ----------------------------------------------------------
#  create table group_user
# ----------------------------------------------------------
CREATE TABLE group_user (
    user_id INTEGER NOT NULL,
    group_id INTEGER NOT NULL,
    permission_key VARCHAR (20) NOT NULL,
    permission_value SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    INDEX group_user_group_id (group_id),
    INDEX group_user_user_id (user_id)
);
# ----------------------------------------------------------
#  create table group_role
# ----------------------------------------------------------
CREATE TABLE group_role (
    role_id INTEGER NOT NULL,
    group_id INTEGER NOT NULL,
    permission_key VARCHAR (20) NOT NULL,
    permission_value SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    INDEX group_role_group_id (group_id),
    INDEX group_role_role_id (role_id)
);
# ----------------------------------------------------------
#  create table group_customer_user
# ----------------------------------------------------------
CREATE TABLE group_customer_user (
    user_id VARCHAR (100) NOT NULL,
    group_id INTEGER NOT NULL,
    permission_key VARCHAR (20) NOT NULL,
    permission_value SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    INDEX group_customer_user_group_id (group_id),
    INDEX group_customer_user_user_id (user_id)
);
# ----------------------------------------------------------
#  create table roles
# ----------------------------------------------------------
CREATE TABLE roles (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX roles_name (name)
);
# ----------------------------------------------------------
#  create table role_user
# ----------------------------------------------------------
CREATE TABLE role_user (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    INDEX role_user_role_id (role_id),
    INDEX role_user_user_id (user_id)
);
# ----------------------------------------------------------
#  create table personal_queues
# ----------------------------------------------------------
CREATE TABLE personal_queues (
    user_id INTEGER NOT NULL,
    queue_id INTEGER NOT NULL,
    INDEX personal_queues_queue_id (queue_id),
    INDEX personal_queues_user_id (user_id)
);
# ----------------------------------------------------------
#  create table salutation
# ----------------------------------------------------------
CREATE TABLE salutation (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    text TEXT NOT NULL,
    content_type VARCHAR (250) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX salutation_name (name)
);
# ----------------------------------------------------------
#  create table signature
# ----------------------------------------------------------
CREATE TABLE signature (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    text TEXT NOT NULL,
    content_type VARCHAR (250) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX signature_name (name)
);
# ----------------------------------------------------------
#  create table system_address
# ----------------------------------------------------------
CREATE TABLE system_address (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    value0 VARCHAR (200) NOT NULL,
    value1 VARCHAR (200) NOT NULL,
    value2 VARCHAR (200) NULL,
    value3 VARCHAR (200) NULL,
    queue_id INTEGER NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table follow_up_possible
# ----------------------------------------------------------
CREATE TABLE follow_up_possible (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX follow_up_possible_name (name)
);
# ----------------------------------------------------------
#  create table queue
# ----------------------------------------------------------
CREATE TABLE queue (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    group_id INTEGER NOT NULL,
    unlock_timeout INTEGER NULL,
    first_response_time INTEGER NULL,
    first_response_notify SMALLINT NULL,
    update_time INTEGER NULL,
    update_notify SMALLINT NULL,
    solution_time INTEGER NULL,
    solution_notify SMALLINT NULL,
    system_address_id SMALLINT NOT NULL,
    calendar_name VARCHAR (100) NULL,
    default_sign_key VARCHAR (100) NULL,
    salutation_id SMALLINT NOT NULL,
    signature_id SMALLINT NOT NULL,
    follow_up_id SMALLINT NOT NULL,
    follow_up_lock SMALLINT NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX queue_name (name),
    INDEX queue_group_id (group_id)
);
# ----------------------------------------------------------
#  create table queue_preferences
# ----------------------------------------------------------
CREATE TABLE queue_preferences (
    queue_id INTEGER NOT NULL,
    preferences_key VARCHAR (150) NOT NULL,
    preferences_value VARCHAR (250) NULL,
    INDEX queue_preferences_queue_id (queue_id)
);
# ----------------------------------------------------------
#  create table ticket_priority
# ----------------------------------------------------------
CREATE TABLE ticket_priority (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_priority_name (name)
);
# ----------------------------------------------------------
#  create table ticket_type
# ----------------------------------------------------------
CREATE TABLE ticket_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_type_name (name)
);
# ----------------------------------------------------------
#  create table ticket_lock_type
# ----------------------------------------------------------
CREATE TABLE ticket_lock_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_lock_type_name (name)
);
# ----------------------------------------------------------
#  create table ticket_state
# ----------------------------------------------------------
CREATE TABLE ticket_state (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    type_id SMALLINT NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_state_name (name)
);
# ----------------------------------------------------------
#  create table ticket_state_type
# ----------------------------------------------------------
CREATE TABLE ticket_state_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_state_type_name (name)
);
# ----------------------------------------------------------
#  create table ticket
# ----------------------------------------------------------
CREATE TABLE ticket (
    id BIGINT NOT NULL AUTO_INCREMENT,
    tn VARCHAR (50) NOT NULL,
    title VARCHAR (255) NULL,
    queue_id INTEGER NOT NULL,
    ticket_lock_id SMALLINT NOT NULL,
    type_id SMALLINT NULL,
    service_id INTEGER NULL,
    sla_id INTEGER NULL,
    user_id INTEGER NOT NULL,
    responsible_user_id INTEGER NOT NULL,
    ticket_priority_id SMALLINT NOT NULL,
    ticket_state_id SMALLINT NOT NULL,
    customer_id VARCHAR (150) NULL,
    customer_user_id VARCHAR (250) NULL,
    timeout INTEGER NOT NULL,
    until_time INTEGER NOT NULL,
    escalation_time INTEGER NOT NULL,
    escalation_update_time INTEGER NOT NULL,
    escalation_response_time INTEGER NOT NULL,
    escalation_solution_time INTEGER NOT NULL,
    valid_id SMALLINT NOT NULL,
    archive_flag SMALLINT NOT NULL DEFAULT 0,
    create_time_unix BIGINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_tn (tn),
    INDEX ticket_archive_flag (archive_flag),
    INDEX ticket_create_time (create_time),
    INDEX ticket_create_time_unix (create_time_unix),
    INDEX ticket_customer_id (customer_id),
    INDEX ticket_customer_user_id (customer_user_id),
    INDEX ticket_escalation_response_time (escalation_response_time),
    INDEX ticket_escalation_solution_time (escalation_solution_time),
    INDEX ticket_escalation_time (escalation_time),
    INDEX ticket_escalation_update_time (escalation_update_time),
    INDEX ticket_queue_id (queue_id),
    INDEX ticket_queue_view (ticket_state_id, ticket_lock_id),
    INDEX ticket_responsible_user_id (responsible_user_id),
    INDEX ticket_ticket_lock_id (ticket_lock_id),
    INDEX ticket_ticket_priority_id (ticket_priority_id),
    INDEX ticket_ticket_state_id (ticket_state_id),
    INDEX ticket_timeout (timeout),
    INDEX ticket_title (title),
    INDEX ticket_type_id (type_id),
    INDEX ticket_until_time (until_time),
    INDEX ticket_user_id (user_id)
);
# ----------------------------------------------------------
#  create table ticket_flag
# ----------------------------------------------------------
CREATE TABLE ticket_flag (
    ticket_id BIGINT NOT NULL,
    ticket_key VARCHAR (50) NOT NULL,
    ticket_value VARCHAR (50) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    UNIQUE INDEX ticket_flag_per_user (ticket_id, ticket_key, create_by),
    INDEX ticket_flag_ticket_id (ticket_id),
    INDEX ticket_flag_ticket_id_create_by (ticket_id, create_by),
    INDEX ticket_flag_ticket_id_ticket_key (ticket_id, ticket_key)
);
# ----------------------------------------------------------
#  create table ticket_history
# ----------------------------------------------------------
CREATE TABLE ticket_history (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    history_type_id SMALLINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    article_id BIGINT NULL,
    type_id SMALLINT NOT NULL,
    queue_id INTEGER NOT NULL,
    owner_id INTEGER NOT NULL,
    priority_id SMALLINT NOT NULL,
    state_id SMALLINT NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    INDEX ticket_history_create_time (create_time),
    INDEX ticket_history_history_type_id (history_type_id),
    INDEX ticket_history_owner_id (owner_id),
    INDEX ticket_history_priority_id (priority_id),
    INDEX ticket_history_queue_id (queue_id),
    INDEX ticket_history_state_id (state_id),
    INDEX ticket_history_ticket_id (ticket_id),
    INDEX ticket_history_type_id (type_id)
);
# ----------------------------------------------------------
#  create table ticket_history_type
# ----------------------------------------------------------
CREATE TABLE ticket_history_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX ticket_history_type_name (name)
);
# ----------------------------------------------------------
#  create table ticket_watcher
# ----------------------------------------------------------
CREATE TABLE ticket_watcher (
    ticket_id BIGINT NOT NULL,
    user_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    INDEX ticket_watcher_ticket_id (ticket_id),
    INDEX ticket_watcher_user_id (user_id)
);
# ----------------------------------------------------------
#  create table ticket_index
# ----------------------------------------------------------
CREATE TABLE ticket_index (
    ticket_id BIGINT NOT NULL,
    queue_id INTEGER NOT NULL,
    queue VARCHAR (200) NOT NULL,
    group_id INTEGER NOT NULL,
    s_lock VARCHAR (200) NOT NULL,
    s_state VARCHAR (200) NOT NULL,
    create_time_unix BIGINT NOT NULL,
    INDEX ticket_index_group_id (group_id),
    INDEX ticket_index_queue_id (queue_id),
    INDEX ticket_index_ticket_id (ticket_id)
);
# ----------------------------------------------------------
#  create table ticket_lock_index
# ----------------------------------------------------------
CREATE TABLE ticket_lock_index (
    ticket_id BIGINT NOT NULL,
    INDEX ticket_lock_index_ticket_id (ticket_id)
);
# ----------------------------------------------------------
#  create table ticket_loop_protection
# ----------------------------------------------------------
CREATE TABLE ticket_loop_protection (
    sent_to VARCHAR (250) NOT NULL,
    sent_date VARCHAR (150) NOT NULL,
    INDEX ticket_loop_protection_sent_date (sent_date),
    INDEX ticket_loop_protection_sent_to (sent_to)
);
# ----------------------------------------------------------
#  create table article_type
# ----------------------------------------------------------
CREATE TABLE article_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX article_type_name (name)
);
# ----------------------------------------------------------
#  create table article_sender_type
# ----------------------------------------------------------
CREATE TABLE article_sender_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX article_sender_type_name (name)
);
# ----------------------------------------------------------
#  create table article_flag
# ----------------------------------------------------------
CREATE TABLE article_flag (
    article_id BIGINT NOT NULL,
    article_key VARCHAR (50) NOT NULL,
    article_value VARCHAR (50) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    INDEX article_flag_article_id (article_id),
    INDEX article_flag_article_id_create_by (article_id, create_by)
);
# ----------------------------------------------------------
#  create table article
# ----------------------------------------------------------
CREATE TABLE article (
    id BIGINT NOT NULL AUTO_INCREMENT,
    ticket_id BIGINT NOT NULL,
    article_type_id SMALLINT NOT NULL,
    article_sender_type_id SMALLINT NOT NULL,
    a_from TEXT NULL,
    a_reply_to TEXT NULL,
    a_to TEXT NULL,
    a_cc TEXT NULL,
    a_subject TEXT NULL,
    a_message_id TEXT NULL,
    a_in_reply_to TEXT NULL,
    a_references TEXT NULL,
    a_content_type VARCHAR (250) NULL,
    a_body MEDIUMTEXT NOT NULL,
    incoming_time INTEGER NOT NULL,
    content_path VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    INDEX article_article_sender_type_id (article_sender_type_id),
    INDEX article_article_type_id (article_type_id),
    INDEX article_message_id (a_message_id(255)),
    INDEX article_ticket_id (ticket_id)
);
# ----------------------------------------------------------
#  create table article_search
# ----------------------------------------------------------
CREATE TABLE article_search (
    id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    article_type_id SMALLINT NOT NULL,
    article_sender_type_id SMALLINT NOT NULL,
    a_from TEXT NULL,
    a_to TEXT NULL,
    a_cc TEXT NULL,
    a_subject TEXT NULL,
    a_message_id TEXT NULL,
    a_body MEDIUMTEXT NOT NULL,
    incoming_time INTEGER NOT NULL,
    PRIMARY KEY(id),
    INDEX article_search_article_sender_type_id (article_sender_type_id),
    INDEX article_search_article_type_id (article_type_id),
    INDEX article_search_message_id (a_message_id(255)),
    INDEX article_search_ticket_id (ticket_id)
);
# ----------------------------------------------------------
#  create table article_plain
# ----------------------------------------------------------
CREATE TABLE article_plain (
    id BIGINT NOT NULL AUTO_INCREMENT,
    article_id BIGINT NOT NULL,
    body LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    INDEX article_plain_article_id (article_id)
);
# ----------------------------------------------------------
#  create table article_attachment
# ----------------------------------------------------------
CREATE TABLE article_attachment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    article_id BIGINT NOT NULL,
    filename VARCHAR (250) NULL,
    content_size VARCHAR (30) NULL,
    content_type TEXT NULL,
    content_id VARCHAR (250) NULL,
    content_alternative VARCHAR (50) NULL,
    content LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    INDEX article_attachment_article_id (article_id)
);
# ----------------------------------------------------------
#  create table time_accounting
# ----------------------------------------------------------
CREATE TABLE time_accounting (
    id BIGINT NOT NULL AUTO_INCREMENT,
    ticket_id BIGINT NOT NULL,
    article_id BIGINT NULL,
    time_unit DECIMAL (10,2) NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    INDEX time_accounting_ticket_id (ticket_id)
);
# ----------------------------------------------------------
#  create table standard_response
# ----------------------------------------------------------
CREATE TABLE standard_response (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    text TEXT NULL,
    content_type VARCHAR (250) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX standard_response_name (name)
);
# ----------------------------------------------------------
#  create table queue_standard_response
# ----------------------------------------------------------
CREATE TABLE queue_standard_response (
    queue_id INTEGER NOT NULL,
    standard_response_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL
);
# ----------------------------------------------------------
#  create table standard_attachment
# ----------------------------------------------------------
CREATE TABLE standard_attachment (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    content_type VARCHAR (250) NOT NULL,
    content LONGBLOB NOT NULL,
    filename VARCHAR (250) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX standard_attachment_name (name)
);
# ----------------------------------------------------------
#  create table standard_response_attachment
# ----------------------------------------------------------
CREATE TABLE standard_response_attachment (
    id INTEGER NOT NULL AUTO_INCREMENT,
    standard_attachment_id INTEGER NOT NULL,
    standard_response_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table auto_response_type
# ----------------------------------------------------------
CREATE TABLE auto_response_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX auto_response_type_name (name)
);
# ----------------------------------------------------------
#  create table auto_response
# ----------------------------------------------------------
CREATE TABLE auto_response (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    text0 TEXT NULL,
    text1 TEXT NULL,
    text2 TEXT NULL,
    type_id SMALLINT NOT NULL,
    system_address_id SMALLINT NOT NULL,
    charset VARCHAR (80) NOT NULL,
    content_type VARCHAR (250) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX auto_response_name (name)
);
# ----------------------------------------------------------
#  create table queue_auto_response
# ----------------------------------------------------------
CREATE TABLE queue_auto_response (
    id INTEGER NOT NULL AUTO_INCREMENT,
    queue_id INTEGER NOT NULL,
    auto_response_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table service
# ----------------------------------------------------------
CREATE TABLE service (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    valid_id SMALLINT NOT NULL,
    comments VARCHAR (250) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX service_name (name)
);
# ----------------------------------------------------------
#  create table service_preferences
# ----------------------------------------------------------
CREATE TABLE service_preferences (
    service_id INTEGER NOT NULL,
    preferences_key VARCHAR (150) NOT NULL,
    preferences_value VARCHAR (250) NULL,
    INDEX service_preferences_service_id (service_id)
);
# ----------------------------------------------------------
#  create table service_customer_user
# ----------------------------------------------------------
CREATE TABLE service_customer_user (
    customer_user_login VARCHAR (200) NOT NULL,
    service_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    INDEX service_customer_user_customer_user_login (customer_user_login(10)),
    INDEX service_customer_user_service_id (service_id)
);
# ----------------------------------------------------------
#  create table sla
# ----------------------------------------------------------
CREATE TABLE sla (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    calendar_name VARCHAR (100) NULL,
    first_response_time INTEGER NOT NULL,
    first_response_notify SMALLINT NULL,
    update_time INTEGER NOT NULL,
    update_notify SMALLINT NULL,
    solution_time INTEGER NOT NULL,
    solution_notify SMALLINT NULL,
    valid_id SMALLINT NOT NULL,
    comments VARCHAR (250) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX sla_name (name)
);
# ----------------------------------------------------------
#  create table sla_preferences
# ----------------------------------------------------------
CREATE TABLE sla_preferences (
    sla_id INTEGER NOT NULL,
    preferences_key VARCHAR (150) NOT NULL,
    preferences_value VARCHAR (250) NULL,
    INDEX sla_preferences_sla_id (sla_id)
);
# ----------------------------------------------------------
#  create table service_sla
# ----------------------------------------------------------
CREATE TABLE service_sla (
    service_id INTEGER NOT NULL,
    sla_id INTEGER NOT NULL,
    UNIQUE INDEX service_sla_service_sla (service_id, sla_id)
);
# ----------------------------------------------------------
#  create table sessions
# ----------------------------------------------------------
CREATE TABLE sessions (
    id BIGINT NOT NULL AUTO_INCREMENT,
    session_id VARCHAR (100) NOT NULL,
    data_key VARCHAR (100) NOT NULL,
    data_value TEXT NULL,
    serialized SMALLINT NOT NULL,
    PRIMARY KEY(id),
    INDEX sessions_data_key (data_key),
    INDEX sessions_session_id_data_key (session_id, data_key)
);
# ----------------------------------------------------------
#  create table customer_user
# ----------------------------------------------------------
CREATE TABLE customer_user (
    id INTEGER NOT NULL AUTO_INCREMENT,
    login VARCHAR (200) NOT NULL,
    email VARCHAR (150) NOT NULL,
    customer_id VARCHAR (150) NOT NULL,
    pw VARCHAR (64) NULL,
    title VARCHAR (50) NULL,
    first_name VARCHAR (100) NOT NULL,
    last_name VARCHAR (100) NOT NULL,
    phone VARCHAR (150) NULL,
    fax VARCHAR (150) NULL,
    mobile VARCHAR (150) NULL,
    street VARCHAR (150) NULL,
    zip VARCHAR (200) NULL,
    city VARCHAR (200) NULL,
    country VARCHAR (200) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX customer_user_login (login)
);
# ----------------------------------------------------------
#  create table customer_preferences
# ----------------------------------------------------------
CREATE TABLE customer_preferences (
    user_id VARCHAR (250) NOT NULL,
    preferences_key VARCHAR (150) NOT NULL,
    preferences_value VARCHAR (250) NULL,
    INDEX customer_preferences_user_id (user_id)
);
# ----------------------------------------------------------
#  create table customer_company
# ----------------------------------------------------------
CREATE TABLE customer_company (
    customer_id VARCHAR (150) NOT NULL,
    name VARCHAR (200) NOT NULL,
    street VARCHAR (200) NULL,
    zip VARCHAR (200) NULL,
    city VARCHAR (200) NULL,
    country VARCHAR (200) NULL,
    url VARCHAR (200) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(customer_id),
    UNIQUE INDEX customer_company_name (name)
);
# ----------------------------------------------------------
#  create table mail_account
# ----------------------------------------------------------
CREATE TABLE mail_account (
    id INTEGER NOT NULL AUTO_INCREMENT,
    login VARCHAR (200) NOT NULL,
    pw VARCHAR (200) NOT NULL,
    host VARCHAR (200) NOT NULL,
    account_type VARCHAR (20) NOT NULL,
    queue_id INTEGER NOT NULL,
    trusted SMALLINT NOT NULL,
    imap_folder VARCHAR (250) NULL,
    comments VARCHAR (250) NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table postmaster_filter
# ----------------------------------------------------------
CREATE TABLE postmaster_filter (
    f_name VARCHAR (200) NOT NULL,
    f_stop SMALLINT NULL,
    f_type VARCHAR (20) NOT NULL,
    f_key VARCHAR (200) NOT NULL,
    f_value VARCHAR (200) NOT NULL,
    INDEX postmaster_filter_f_name (f_name)
);
# ----------------------------------------------------------
#  create table generic_agent_jobs
# ----------------------------------------------------------
CREATE TABLE generic_agent_jobs (
    job_name VARCHAR (200) NOT NULL,
    job_key VARCHAR (200) NOT NULL,
    job_value VARCHAR (200) NULL,
    INDEX generic_agent_jobs_job_name (job_name)
);
# ----------------------------------------------------------
#  create table search_profile
# ----------------------------------------------------------
CREATE TABLE search_profile (
    login VARCHAR (200) NOT NULL,
    profile_name VARCHAR (200) NOT NULL,
    profile_type VARCHAR (30) NOT NULL,
    profile_key VARCHAR (200) NOT NULL,
    profile_value VARCHAR (200) NULL,
    INDEX search_profile_login (login),
    INDEX search_profile_profile_name (profile_name)
);
# ----------------------------------------------------------
#  create table process_id
# ----------------------------------------------------------
CREATE TABLE process_id (
    process_name VARCHAR (200) NOT NULL,
    process_id VARCHAR (200) NOT NULL,
    process_host VARCHAR (200) NOT NULL,
    process_create INTEGER NOT NULL,
    process_change INTEGER NOT NULL
);
# ----------------------------------------------------------
#  create table web_upload_cache
# ----------------------------------------------------------
CREATE TABLE web_upload_cache (
    form_id VARCHAR (250) NULL,
    filename VARCHAR (250) NULL,
    content_id VARCHAR (250) NULL,
    content_size VARCHAR (30) NULL,
    content_type VARCHAR (250) NULL,
    content LONGBLOB NOT NULL,
    create_time_unix BIGINT NOT NULL
);
# ----------------------------------------------------------
#  create table notifications
# ----------------------------------------------------------
CREATE TABLE notifications (
    id INTEGER NOT NULL AUTO_INCREMENT,
    notification_type VARCHAR (200) NOT NULL,
    notification_charset VARCHAR (60) NOT NULL,
    notification_language VARCHAR (60) NOT NULL,
    subject VARCHAR (200) NOT NULL,
    text TEXT NOT NULL,
    content_type VARCHAR (250) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table notification_event
# ----------------------------------------------------------
CREATE TABLE notification_event (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    subject VARCHAR (200) NOT NULL,
    text TEXT NOT NULL,
    content_type VARCHAR (250) NOT NULL,
    charset VARCHAR (100) NOT NULL,
    valid_id SMALLINT NOT NULL,
    comments VARCHAR (250) NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX notification_event_name (name)
);
# ----------------------------------------------------------
#  create table notification_event_item
# ----------------------------------------------------------
CREATE TABLE notification_event_item (
    notification_id INTEGER NOT NULL,
    event_key VARCHAR (200) NOT NULL,
    event_value VARCHAR (200) NOT NULL,
    INDEX notification_event_item_event_key (event_key),
    INDEX notification_event_item_event_value (event_value),
    INDEX notification_event_item_notification_id (notification_id)
);
# ----------------------------------------------------------
#  create table link_type
# ----------------------------------------------------------
CREATE TABLE link_type (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (50) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX link_type_name (name)
);
# ----------------------------------------------------------
#  create table link_state
# ----------------------------------------------------------
CREATE TABLE link_state (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (50) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX link_state_name (name)
);
# ----------------------------------------------------------
#  create table link_object
# ----------------------------------------------------------
CREATE TABLE link_object (
    id SMALLINT NOT NULL AUTO_INCREMENT,
    name VARCHAR (100) NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX link_object_name (name)
);
# ----------------------------------------------------------
#  create table link_relation
# ----------------------------------------------------------
CREATE TABLE link_relation (
    source_object_id SMALLINT NOT NULL,
    source_key VARCHAR (50) NOT NULL,
    target_object_id SMALLINT NOT NULL,
    target_key VARCHAR (50) NOT NULL,
    type_id SMALLINT NOT NULL,
    state_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    UNIQUE INDEX link_relation_view (source_object_id, source_key, target_object_id, target_key, type_id)
);
# ----------------------------------------------------------
#  create table xml_storage
# ----------------------------------------------------------
CREATE TABLE xml_storage (
    xml_type VARCHAR (200) NOT NULL,
    xml_key VARCHAR (250) NOT NULL,
    xml_content_key VARCHAR (250) NOT NULL,
    xml_content_value MEDIUMTEXT NULL,
    INDEX xml_storage_key_type (xml_key(10), xml_type(10)),
    INDEX xml_storage_xml_content_key (xml_content_key(100))
);
# ----------------------------------------------------------
#  create table virtual_fs
# ----------------------------------------------------------
CREATE TABLE virtual_fs (
    id BIGINT NOT NULL AUTO_INCREMENT,
    filename TEXT NOT NULL,
    backend VARCHAR (60) NOT NULL,
    backend_key VARCHAR (160) NOT NULL,
    create_time DATETIME NOT NULL,
    PRIMARY KEY(id),
    INDEX virtual_fs_backend (backend(60)),
    INDEX virtual_fs_filename (filename(350))
);
# ----------------------------------------------------------
#  create table virtual_fs_preferences
# ----------------------------------------------------------
CREATE TABLE virtual_fs_preferences (
    virtual_fs_id BIGINT NOT NULL,
    preferences_key VARCHAR (150) NOT NULL,
    preferences_value TEXT NULL,
    INDEX virtual_fs_preferences_key_value (preferences_key, preferences_value(150)),
    INDEX virtual_fs_preferences_virtual_fs_id (virtual_fs_id)
);
# ----------------------------------------------------------
#  create table virtual_fs_db
# ----------------------------------------------------------
CREATE TABLE virtual_fs_db (
    id BIGINT NOT NULL AUTO_INCREMENT,
    filename TEXT NOT NULL,
    content LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    PRIMARY KEY(id),
    INDEX virtual_fs_db_filename (filename(350))
);
# ----------------------------------------------------------
#  create table package_repository
# ----------------------------------------------------------
CREATE TABLE package_repository (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    version VARCHAR (250) NOT NULL,
    vendor VARCHAR (250) NOT NULL,
    install_status VARCHAR (250) NOT NULL,
    filename VARCHAR (250) NULL,
    content_size VARCHAR (30) NULL,
    content_type VARCHAR (250) NULL,
    content LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table gi_webservice_config
# ----------------------------------------------------------
CREATE TABLE gi_webservice_config (
    id INTEGER NOT NULL AUTO_INCREMENT,
    name VARCHAR (200) NOT NULL,
    config LONGBLOB NOT NULL,
    config_md5 VARCHAR (32) NOT NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX gi_webservice_config_config_md5 (config_md5),
    UNIQUE INDEX gi_webservice_config_name (name)
);
# ----------------------------------------------------------
#  create table gi_webservice_config_history
# ----------------------------------------------------------
CREATE TABLE gi_webservice_config_history (
    id BIGINT NOT NULL AUTO_INCREMENT,
    config_id INTEGER NOT NULL,
    config LONGBLOB NOT NULL,
    config_md5 VARCHAR (32) NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX gi_webservice_config_history_config_md5 (config_md5)
);
# ----------------------------------------------------------
#  create table scheduler_task_list
# ----------------------------------------------------------
CREATE TABLE scheduler_task_list (
    id BIGINT NOT NULL AUTO_INCREMENT,
    task_data TEXT NOT NULL,
    task_data_md5 VARCHAR (32) NOT NULL,
    task_type VARCHAR (200) NOT NULL,
    due_time DATETIME NOT NULL,
    create_time DATETIME NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX scheduler_task_list_task_data_md5 (task_data_md5)
);
# ----------------------------------------------------------
#  create table gi_debugger_entry
# ----------------------------------------------------------
CREATE TABLE gi_debugger_entry (
    id BIGINT NOT NULL AUTO_INCREMENT,
    communication_id VARCHAR (32) NOT NULL,
    communication_type VARCHAR (50) NOT NULL,
    remote_ip VARCHAR (50) NULL,
    webservice_id INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX gi_debugger_entry_communication_id (communication_id),
    INDEX gi_debugger_entry_create_time (create_time)
);
# ----------------------------------------------------------
#  create table gi_debugger_entry_content
# ----------------------------------------------------------
CREATE TABLE gi_debugger_entry_content (
    id BIGINT NOT NULL AUTO_INCREMENT,
    gi_debugger_entry_id BIGINT NOT NULL,
    debug_level VARCHAR (50) NOT NULL,
    subject VARCHAR (255) NOT NULL,
    content LONGBLOB NULL,
    create_time DATETIME NOT NULL,
    PRIMARY KEY(id),
    INDEX gi_debugger_entry_content_create_time (create_time),
    INDEX gi_debugger_entry_content_debug_level (debug_level)
);
# ----------------------------------------------------------
#  create table gi_object_lock_state
# ----------------------------------------------------------
CREATE TABLE gi_object_lock_state (
    webservice_id INTEGER NOT NULL,
    object_type VARCHAR (30) NOT NULL,
    object_id BIGINT NOT NULL,
    lock_state VARCHAR (30) NOT NULL,
    lock_state_counter INTEGER NOT NULL,
    create_time DATETIME NOT NULL,
    change_time DATETIME NOT NULL,
    UNIQUE INDEX gi_object_lock_state_list (webservice_id, object_type, object_id),
    INDEX object_lock_state_list_state (webservice_id, object_type, object_id, lock_state)
);
# ----------------------------------------------------------
#  create table smime_signer_cert_relations
# ----------------------------------------------------------
CREATE TABLE smime_signer_cert_relations (
    id INTEGER NOT NULL AUTO_INCREMENT,
    cert_hash VARCHAR (8) NOT NULL,
    cert_fingerprint VARCHAR (59) NOT NULL,
    ca_hash VARCHAR (8) NOT NULL,
    ca_fingerprint VARCHAR (59) NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id)
);
# ----------------------------------------------------------
#  create table dynamic_field_value
# ----------------------------------------------------------
CREATE TABLE dynamic_field_value (
    id INTEGER NOT NULL AUTO_INCREMENT,
    field_id INTEGER NOT NULL,
    object_id BIGINT NOT NULL,
    value_text TEXT NULL,
    value_date DATETIME NULL,
    value_int BIGINT NULL,
    PRIMARY KEY(id),
    INDEX index_field_values (field_id, object_id),
    INDEX index_search_date (field_id, value_date),
    INDEX index_search_int (field_id, value_int)
);
# ----------------------------------------------------------
#  create table dynamic_field
# ----------------------------------------------------------
CREATE TABLE dynamic_field (
    id INTEGER NOT NULL AUTO_INCREMENT,
    internal_field SMALLINT NOT NULL DEFAULT 0,
    name VARCHAR (200) NOT NULL,
    label VARCHAR (200) NOT NULL,
    field_order INTEGER NOT NULL,
    field_type VARCHAR (200) NOT NULL,
    object_type VARCHAR (200) NOT NULL,
    config LONGBLOB NULL,
    valid_id SMALLINT NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX dynamic_field_name (name)
);
# ----------------------------------------------------------
#  create table pm_process
# ----------------------------------------------------------
CREATE TABLE pm_process (
    id INTEGER NOT NULL AUTO_INCREMENT,
    entity_id VARCHAR (50) NOT NULL,
    name VARCHAR (200) NOT NULL,
    state_entity_id VARCHAR (50) NOT NULL,
    layout LONGBLOB NOT NULL,
    config LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX pm_process_entity_id (entity_id)
);
# ----------------------------------------------------------
#  create table pm_activity
# ----------------------------------------------------------
CREATE TABLE pm_activity (
    id INTEGER NOT NULL AUTO_INCREMENT,
    entity_id VARCHAR (50) NOT NULL,
    name VARCHAR (200) NOT NULL,
    config LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX pm_activity_entity_id (entity_id)
);
# ----------------------------------------------------------
#  create table pm_activity_dialog
# ----------------------------------------------------------
CREATE TABLE pm_activity_dialog (
    id INTEGER NOT NULL AUTO_INCREMENT,
    entity_id VARCHAR (50) NOT NULL,
    name VARCHAR (200) NOT NULL,
    config LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX pm_activity_dialog_entity_id (entity_id)
);
# ----------------------------------------------------------
#  create table pm_transition
# ----------------------------------------------------------
CREATE TABLE pm_transition (
    id INTEGER NOT NULL AUTO_INCREMENT,
    entity_id VARCHAR (50) NOT NULL,
    name VARCHAR (200) NOT NULL,
    config LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX pm_transition_entity_id (entity_id)
);
# ----------------------------------------------------------
#  create table pm_transition_action
# ----------------------------------------------------------
CREATE TABLE pm_transition_action (
    id INTEGER NOT NULL AUTO_INCREMENT,
    entity_id VARCHAR (50) NOT NULL,
    name VARCHAR (200) NOT NULL,
    config LONGBLOB NOT NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    change_time DATETIME NOT NULL,
    change_by INTEGER NOT NULL,
    PRIMARY KEY(id),
    UNIQUE INDEX pm_transition_action_entity_id (entity_id)
);
# ----------------------------------------------------------
#  create table pm_entity
# ----------------------------------------------------------
CREATE TABLE pm_entity (
    entity_type VARCHAR (50) NOT NULL,
    entity_counter INTEGER NOT NULL
);
# ----------------------------------------------------------
#  create table pm_entity_sync
# ----------------------------------------------------------
CREATE TABLE pm_entity_sync (
    entity_type VARCHAR (30) NOT NULL,
    entity_id VARCHAR (50) NOT NULL,
    sync_state VARCHAR (30) NOT NULL,
    create_time DATETIME NOT NULL,
    change_time DATETIME NOT NULL,
    UNIQUE INDEX pm_entity_sync_list (entity_type, entity_id)
);
