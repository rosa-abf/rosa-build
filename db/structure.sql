--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activity_feeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_feeds (
    id integer NOT NULL,
    user_id integer NOT NULL,
    kind character varying(255),
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_feeds_id_seq OWNED BY activity_feeds.id;


--
-- Name: advisories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advisories (
    id integer NOT NULL,
    advisory_id character varying(255),
    description text DEFAULT ''::text,
    "references" text DEFAULT ''::text,
    update_type text DEFAULT ''::text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: advisories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE advisories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: advisories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE advisories_id_seq OWNED BY advisories.id;


--
-- Name: advisories_platforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advisories_platforms (
    advisory_id integer,
    platform_id integer
);


--
-- Name: advisories_projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advisories_projects (
    advisory_id integer,
    project_id integer
);


--
-- Name: arches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE arches (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: arches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE arches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE arches_id_seq OWNED BY arches.id;


--
-- Name: authentications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE authentications (
    id integer NOT NULL,
    user_id integer,
    provider character varying(255),
    uid character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: authentications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authentications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authentications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authentications_id_seq OWNED BY authentications.id;


--
-- Name: build_list_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE build_list_items (
    id integer NOT NULL,
    name character varying(255),
    level integer,
    status integer,
    build_list_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    version character varying(255)
);


--
-- Name: build_list_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE build_list_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: build_list_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE build_list_items_id_seq OWNED BY build_list_items.id;


--
-- Name: build_list_packages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE build_list_packages (
    id integer NOT NULL,
    build_list_id integer,
    project_id integer,
    platform_id integer,
    fullname character varying(255),
    name character varying(255),
    version character varying(255),
    release character varying(255),
    package_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    actual boolean DEFAULT false
);


--
-- Name: build_list_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE build_list_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: build_list_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE build_list_packages_id_seq OWNED BY build_list_packages.id;


--
-- Name: build_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE build_lists (
    id integer NOT NULL,
    bs_id integer,
    container_path character varying(255),
    status integer,
    project_version character varying(255),
    project_id integer,
    arch_id integer,
    notified_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_circle boolean DEFAULT false,
    additional_repos text,
    name character varying(255),
    build_requires boolean DEFAULT false,
    update_type character varying(255),
    build_for_platform_id integer,
    save_to_platform_id integer,
    include_repos text,
    user_id integer,
    auto_publish boolean DEFAULT true,
    package_version character varying(255),
    commit_hash character varying(255),
    priority integer DEFAULT 0 NOT NULL,
    started_at timestamp without time zone,
    duration integer,
    advisory_id integer,
    mass_build_id integer,
    save_to_repository_id integer,
    results text,
    new_core boolean,
    last_published_commit_hash character varying(255)
);


--
-- Name: build_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE build_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: build_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE build_lists_id_seq OWNED BY build_lists.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    commentable_type character varying(255),
    user_id integer,
    body text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    commentable_id numeric(50,0),
    project_id integer,
    data text
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: event_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_logs (
    id integer NOT NULL,
    user_id integer,
    user_name character varying(255),
    eventable_id integer,
    eventable_type character varying(255),
    eventable_name character varying(255),
    ip character varying(255),
    kind character varying(255),
    protocol character varying(255),
    controller character varying(255),
    action character varying(255),
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_logs_id_seq OWNED BY event_logs.id;


--
-- Name: flash_notifies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flash_notifies (
    id integer NOT NULL,
    body_ru text NOT NULL,
    body_en text NOT NULL,
    status character varying(255) NOT NULL,
    published boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flash_notifies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flash_notifies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flash_notifies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flash_notifies_id_seq OWNED BY flash_notifies.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    owner_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uname character varying(255),
    own_projects_count integer DEFAULT 0 NOT NULL,
    description text,
    avatar_file_name character varying(255),
    avatar_content_type character varying(255),
    avatar_file_size integer,
    avatar_updated_at timestamp without time zone
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE issues (
    id integer NOT NULL,
    serial_id integer,
    project_id integer,
    assignee_id integer,
    title character varying(255),
    body text,
    status character varying(255) DEFAULT 'open'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    closed_at timestamp without time zone,
    closed_by integer
);


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE issues_id_seq OWNED BY issues.id;


--
-- Name: key_pairs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE key_pairs (
    id integer NOT NULL,
    public text NOT NULL,
    encrypted_secret text NOT NULL,
    key_id character varying(255) NOT NULL,
    user_id integer NOT NULL,
    repository_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: key_pairs_backup; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE key_pairs_backup (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    user_id integer NOT NULL,
    key_id character varying(255) NOT NULL,
    public text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: key_pairs_backup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE key_pairs_backup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: key_pairs_backup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE key_pairs_backup_id_seq OWNED BY key_pairs_backup.id;


--
-- Name: key_pairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE key_pairs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: key_pairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE key_pairs_id_seq OWNED BY key_pairs.id;


--
-- Name: labelings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE labelings (
    id integer NOT NULL,
    label_id integer NOT NULL,
    issue_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: labelings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE labelings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labelings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE labelings_id_seq OWNED BY labelings.id;


--
-- Name: labels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE labels (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    color character varying(255) NOT NULL,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE labels_id_seq OWNED BY labels.id;


--
-- Name: mass_builds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mass_builds (
    id integer NOT NULL,
    platform_id integer,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    arch_names character varying(255),
    user_id integer,
    auto_publish boolean DEFAULT false NOT NULL,
    build_lists_count integer DEFAULT 0 NOT NULL,
    build_published_count integer DEFAULT 0 NOT NULL,
    build_pending_count integer DEFAULT 0 NOT NULL,
    build_started_count integer DEFAULT 0 NOT NULL,
    build_publish_count integer DEFAULT 0 NOT NULL,
    build_error_count integer DEFAULT 0 NOT NULL,
    stop_build boolean DEFAULT false NOT NULL,
    projects_list text,
    missed_projects_count integer DEFAULT 0 NOT NULL,
    missed_projects_list text
);


--
-- Name: mass_builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mass_builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mass_builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mass_builds_id_seq OWNED BY mass_builds.id;


--
-- Name: platforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE platforms (
    id integer NOT NULL,
    description character varying(255),
    name character varying(255) NOT NULL,
    parent_platform_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    released boolean DEFAULT false NOT NULL,
    owner_id integer,
    owner_type character varying(255),
    visibility character varying(255) DEFAULT 'open'::character varying NOT NULL,
    platform_type character varying(255) DEFAULT 'main'::character varying NOT NULL,
    distrib_type character varying(255) NOT NULL
);


--
-- Name: platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE platforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE platforms_id_seq OWNED BY platforms.id;


--
-- Name: private_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE private_users (
    id integer NOT NULL,
    platform_id integer,
    login character varying(255),
    password character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: private_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE private_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: private_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE private_users_id_seq OWNED BY private_users.id;


--
-- Name: product_build_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_build_lists (
    id integer NOT NULL,
    product_id integer,
    status integer DEFAULT 2 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer,
    project_version character varying(255),
    commit_hash character varying(255),
    params character varying(255),
    main_script character varying(255),
    results text,
    arch_id integer,
    time_living integer,
    user_id integer
);


--
-- Name: product_build_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_build_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_build_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_build_lists_id_seq OWNED BY product_build_lists.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    platform_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    project_id integer,
    params character varying(255),
    main_script character varying(255),
    time_living integer
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: project_imports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE project_imports (
    id integer NOT NULL,
    project_id integer,
    name character varying(255),
    version character varying(255),
    file_mtime timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    platform_id integer
);


--
-- Name: project_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_imports_id_seq OWNED BY project_imports.id;


--
-- Name: project_to_repositories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE project_to_repositories (
    id integer NOT NULL,
    project_id integer,
    repository_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: project_to_repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_to_repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_to_repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_to_repositories_id_seq OWNED BY project_to_repositories.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    owner_id integer,
    owner_type character varying(255),
    visibility character varying(255) DEFAULT 'open'::character varying,
    description text,
    ancestry character varying(255),
    has_issues boolean DEFAULT true,
    srpm_file_name character varying(255),
    srpm_file_size integer,
    srpm_updated_at timestamp without time zone,
    srpm_content_type character varying(255),
    has_wiki boolean DEFAULT false,
    default_branch character varying(255) DEFAULT 'master'::character varying,
    is_package boolean DEFAULT true NOT NULL,
    average_build_time integer DEFAULT 0 NOT NULL,
    build_count integer DEFAULT 0 NOT NULL,
    maintainer_id integer
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: pull_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pull_requests (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    to_project_id integer NOT NULL,
    from_project_id integer NOT NULL,
    to_ref character varying(255) NOT NULL,
    from_ref character varying(255) NOT NULL,
    from_project_owner_uname character varying(255),
    from_project_name character varying(255)
);


--
-- Name: pull_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pull_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pull_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pull_requests_id_seq OWNED BY pull_requests.id;


--
-- Name: register_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE register_requests (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255),
    token character varying(255),
    approved boolean DEFAULT false,
    rejected boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    interest character varying(255),
    more text,
    language character varying(255)
);


--
-- Name: register_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE register_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: register_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE register_requests_id_seq OWNED BY register_requests.id;


--
-- Name: relations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE relations (
    id integer NOT NULL,
    actor_id integer,
    actor_type character varying(255),
    target_id integer,
    target_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    role character varying(255)
);


--
-- Name: relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE relations_id_seq OWNED BY relations.id;


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE repositories (
    id integer NOT NULL,
    description character varying(255) NOT NULL,
    platform_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255) NOT NULL,
    publish_without_qa boolean DEFAULT true
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE repositories_id_seq OWNED BY repositories.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: settings_notifiers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE settings_notifiers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    can_notify boolean DEFAULT true,
    new_comment boolean DEFAULT true,
    new_comment_reply boolean DEFAULT true,
    new_issue boolean DEFAULT true,
    issue_assign boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    new_comment_commit_owner boolean DEFAULT true,
    new_comment_commit_repo_owner boolean DEFAULT true,
    new_comment_commit_commentor boolean DEFAULT true,
    new_build boolean DEFAULT true,
    new_associated_build boolean DEFAULT true
);


--
-- Name: settings_notifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE settings_notifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_notifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE settings_notifiers_id_seq OWNED BY settings_notifiers.id;


--
-- Name: subscribes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscribes (
    id integer NOT NULL,
    subscribeable_type character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status boolean DEFAULT true,
    project_id integer,
    subscribeable_id numeric(50,0)
);


--
-- Name: subscribes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscribes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscribes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscribes_id_seq OWNED BY subscribes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    ssh_key text,
    uname character varying(255),
    role character varying(255),
    language character varying(255) DEFAULT 'en'::character varying,
    own_projects_count integer DEFAULT 0 NOT NULL,
    professional_experience text,
    site character varying(255),
    company character varying(255),
    location character varying(255),
    avatar_file_name character varying(255),
    avatar_content_type character varying(255),
    avatar_file_size integer,
    avatar_updated_at timestamp without time zone,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    authentication_token character varying(255),
    build_priority integer DEFAULT 50
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_feeds ALTER COLUMN id SET DEFAULT nextval('activity_feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY advisories ALTER COLUMN id SET DEFAULT nextval('advisories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY arches ALTER COLUMN id SET DEFAULT nextval('arches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authentications ALTER COLUMN id SET DEFAULT nextval('authentications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY build_list_items ALTER COLUMN id SET DEFAULT nextval('build_list_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY build_list_packages ALTER COLUMN id SET DEFAULT nextval('build_list_packages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY build_lists ALTER COLUMN id SET DEFAULT nextval('build_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_logs ALTER COLUMN id SET DEFAULT nextval('event_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flash_notifies ALTER COLUMN id SET DEFAULT nextval('flash_notifies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues ALTER COLUMN id SET DEFAULT nextval('issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY key_pairs ALTER COLUMN id SET DEFAULT nextval('key_pairs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY key_pairs_backup ALTER COLUMN id SET DEFAULT nextval('key_pairs_backup_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY labelings ALTER COLUMN id SET DEFAULT nextval('labelings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels ALTER COLUMN id SET DEFAULT nextval('labels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mass_builds ALTER COLUMN id SET DEFAULT nextval('mass_builds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY platforms ALTER COLUMN id SET DEFAULT nextval('platforms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY private_users ALTER COLUMN id SET DEFAULT nextval('private_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_build_lists ALTER COLUMN id SET DEFAULT nextval('product_build_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_imports ALTER COLUMN id SET DEFAULT nextval('project_imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_to_repositories ALTER COLUMN id SET DEFAULT nextval('project_to_repositories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pull_requests ALTER COLUMN id SET DEFAULT nextval('pull_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY register_requests ALTER COLUMN id SET DEFAULT nextval('register_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY relations ALTER COLUMN id SET DEFAULT nextval('relations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY repositories ALTER COLUMN id SET DEFAULT nextval('repositories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings_notifiers ALTER COLUMN id SET DEFAULT nextval('settings_notifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscribes ALTER COLUMN id SET DEFAULT nextval('subscribes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: activity_feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_feeds
    ADD CONSTRAINT activity_feeds_pkey PRIMARY KEY (id);


--
-- Name: advisories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advisories
    ADD CONSTRAINT advisories_pkey PRIMARY KEY (id);


--
-- Name: arches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY arches
    ADD CONSTRAINT arches_pkey PRIMARY KEY (id);


--
-- Name: authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY authentications
    ADD CONSTRAINT authentications_pkey PRIMARY KEY (id);


--
-- Name: build_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY build_list_items
    ADD CONSTRAINT build_list_items_pkey PRIMARY KEY (id);


--
-- Name: build_list_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY build_list_packages
    ADD CONSTRAINT build_list_packages_pkey PRIMARY KEY (id);


--
-- Name: build_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY build_lists
    ADD CONSTRAINT build_lists_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_logs
    ADD CONSTRAINT event_logs_pkey PRIMARY KEY (id);


--
-- Name: flash_notifies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flash_notifies
    ADD CONSTRAINT flash_notifies_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: key_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY key_pairs_backup
    ADD CONSTRAINT key_pairs_pkey PRIMARY KEY (id);


--
-- Name: key_pairs_pkey1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY key_pairs
    ADD CONSTRAINT key_pairs_pkey1 PRIMARY KEY (id);


--
-- Name: labelings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY labelings
    ADD CONSTRAINT labelings_pkey PRIMARY KEY (id);


--
-- Name: labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: mass_builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mass_builds
    ADD CONSTRAINT mass_builds_pkey PRIMARY KEY (id);


--
-- Name: platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (id);


--
-- Name: private_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY private_users
    ADD CONSTRAINT private_users_pkey PRIMARY KEY (id);


--
-- Name: product_build_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_build_lists
    ADD CONSTRAINT product_build_lists_pkey PRIMARY KEY (id);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: project_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_imports
    ADD CONSTRAINT project_imports_pkey PRIMARY KEY (id);


--
-- Name: project_to_repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_to_repositories
    ADD CONSTRAINT project_to_repositories_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: pull_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pull_requests
    ADD CONSTRAINT pull_requests_pkey PRIMARY KEY (id);


--
-- Name: register_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY register_requests
    ADD CONSTRAINT register_requests_pkey PRIMARY KEY (id);


--
-- Name: relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (id);


--
-- Name: repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: settings_notifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY settings_notifiers
    ADD CONSTRAINT settings_notifiers_pkey PRIMARY KEY (id);


--
-- Name: subscribes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscribes
    ADD CONSTRAINT subscribes_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: advisory_platform_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX advisory_platform_index ON advisories_platforms USING btree (advisory_id, platform_id);


--
-- Name: advisory_project_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX advisory_project_index ON advisories_projects USING btree (advisory_id, project_id);


--
-- Name: index_advisories_on_advisory_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_advisories_on_advisory_id ON advisories USING btree (advisory_id);


--
-- Name: index_advisories_on_update_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_advisories_on_update_type ON advisories USING btree (update_type);


--
-- Name: index_advisories_platforms_on_advisory_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_advisories_platforms_on_advisory_id ON advisories_platforms USING btree (advisory_id);


--
-- Name: index_advisories_platforms_on_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_advisories_platforms_on_platform_id ON advisories_platforms USING btree (platform_id);


--
-- Name: index_advisories_projects_on_advisory_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_advisories_projects_on_advisory_id ON advisories_projects USING btree (advisory_id);


--
-- Name: index_advisories_projects_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_advisories_projects_on_project_id ON advisories_projects USING btree (project_id);


--
-- Name: index_arches_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_arches_on_name ON arches USING btree (name);


--
-- Name: index_authentications_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_authentications_on_provider_and_uid ON authentications USING btree (provider, uid);


--
-- Name: index_authentications_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_authentications_on_user_id ON authentications USING btree (user_id);


--
-- Name: index_build_list_items_on_build_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_list_items_on_build_list_id ON build_list_items USING btree (build_list_id);


--
-- Name: index_build_list_packages_on_actual_and_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_list_packages_on_actual_and_platform_id ON build_list_packages USING btree (actual, platform_id);


--
-- Name: index_build_list_packages_on_build_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_list_packages_on_build_list_id ON build_list_packages USING btree (build_list_id);


--
-- Name: index_build_list_packages_on_name_and_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_list_packages_on_name_and_project_id ON build_list_packages USING btree (name, project_id);


--
-- Name: index_build_list_packages_on_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_list_packages_on_platform_id ON build_list_packages USING btree (platform_id);


--
-- Name: index_build_list_packages_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_list_packages_on_project_id ON build_list_packages USING btree (project_id);


--
-- Name: index_build_lists_on_advisory_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_lists_on_advisory_id ON build_lists USING btree (advisory_id);


--
-- Name: index_build_lists_on_arch_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_lists_on_arch_id ON build_lists USING btree (arch_id);


--
-- Name: index_build_lists_on_bs_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_build_lists_on_bs_id ON build_lists USING btree (bs_id);


--
-- Name: index_build_lists_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_build_lists_on_project_id ON build_lists USING btree (project_id);


--
-- Name: index_issues_on_project_id_and_serial_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_issues_on_project_id_and_serial_id ON issues USING btree (project_id, serial_id);


--
-- Name: index_key_pairs_backup_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_key_pairs_backup_on_repository_id ON key_pairs_backup USING btree (repository_id);


--
-- Name: index_key_pairs_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_key_pairs_on_repository_id ON key_pairs USING btree (repository_id);


--
-- Name: index_labelings_on_issue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_labelings_on_issue_id ON labelings USING btree (issue_id);


--
-- Name: index_labels_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_labels_on_project_id ON labels USING btree (project_id);


--
-- Name: index_platforms_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_platforms_on_name ON platforms USING btree (lower((name)::text));


--
-- Name: index_product_build_lists_on_product_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_build_lists_on_product_id ON product_build_lists USING btree (product_id);


--
-- Name: index_project_imports_on_name_and_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_project_imports_on_name_and_platform_id ON project_imports USING btree (lower((name)::text), platform_id);


--
-- Name: index_project_to_repositories_on_repository_id_and_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_project_to_repositories_on_repository_id_and_project_id ON project_to_repositories USING btree (repository_id, project_id);


--
-- Name: index_projects_on_name_and_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_projects_on_name_and_owner_id_and_owner_type ON projects USING btree (lower((name)::text), owner_id, lower((owner_type)::text));


--
-- Name: index_pull_requests_on_base_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pull_requests_on_base_project_id ON pull_requests USING btree (to_project_id);


--
-- Name: index_pull_requests_on_head_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pull_requests_on_head_project_id ON pull_requests USING btree (from_project_id);


--
-- Name: index_pull_requests_on_issue_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pull_requests_on_issue_id ON pull_requests USING btree (issue_id);


--
-- Name: index_register_requests_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_register_requests_on_email ON register_requests USING btree (lower((email)::text));


--
-- Name: index_register_requests_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_register_requests_on_token ON register_requests USING btree (lower((token)::text));


--
-- Name: index_repositories_on_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_platform_id ON repositories USING btree (platform_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_uname; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_uname ON users USING btree (uname);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: maintainer_search_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX maintainer_search_index ON build_lists USING btree (project_id, save_to_repository_id, build_for_platform_id, arch_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20110309144736');

INSERT INTO schema_migrations (version) VALUES ('20110309173339');

INSERT INTO schema_migrations (version) VALUES ('20110309173421');

INSERT INTO schema_migrations (version) VALUES ('20110311154011');

INSERT INTO schema_migrations (version) VALUES ('20110311154044');

INSERT INTO schema_migrations (version) VALUES ('20110311154136');

INSERT INTO schema_migrations (version) VALUES ('20110311154929');

INSERT INTO schema_migrations (version) VALUES ('20110312133121');

INSERT INTO schema_migrations (version) VALUES ('20110312133559');

INSERT INTO schema_migrations (version) VALUES ('20110312133948');

INSERT INTO schema_migrations (version) VALUES ('20110317130503');

INSERT INTO schema_migrations (version) VALUES ('20110405161609');

INSERT INTO schema_migrations (version) VALUES ('20110407144147');

INSERT INTO schema_migrations (version) VALUES ('20110408123808');

INSERT INTO schema_migrations (version) VALUES ('20110408132541');

INSERT INTO schema_migrations (version) VALUES ('20110408134718');

INSERT INTO schema_migrations (version) VALUES ('20110411082826');

INSERT INTO schema_migrations (version) VALUES ('20110411125015');

INSERT INTO schema_migrations (version) VALUES ('20110411160955');

INSERT INTO schema_migrations (version) VALUES ('20110412074038');

INSERT INTO schema_migrations (version) VALUES ('20110414145300');

INSERT INTO schema_migrations (version) VALUES ('20110428132112');

INSERT INTO schema_migrations (version) VALUES ('20110428140753');

INSERT INTO schema_migrations (version) VALUES ('20111011182847');

INSERT INTO schema_migrations (version) VALUES ('20111011200645');

INSERT INTO schema_migrations (version) VALUES ('20111012065448');

INSERT INTO schema_migrations (version) VALUES ('20111012133633');

INSERT INTO schema_migrations (version) VALUES ('20111012223006');

INSERT INTO schema_migrations (version) VALUES ('20111012223306');

INSERT INTO schema_migrations (version) VALUES ('20111012223521');

INSERT INTO schema_migrations (version) VALUES ('20111012223944');

INSERT INTO schema_migrations (version) VALUES ('20111013150125');

INSERT INTO schema_migrations (version) VALUES ('20111014150436');

INSERT INTO schema_migrations (version) VALUES ('20111016130557');

INSERT INTO schema_migrations (version) VALUES ('20111016220428');

INSERT INTO schema_migrations (version) VALUES ('20111016224709');

INSERT INTO schema_migrations (version) VALUES ('20111016225240');

INSERT INTO schema_migrations (version) VALUES ('20111017112255');

INSERT INTO schema_migrations (version) VALUES ('20111017152936');

INSERT INTO schema_migrations (version) VALUES ('20111017172701');

INSERT INTO schema_migrations (version) VALUES ('20111018102655');

INSERT INTO schema_migrations (version) VALUES ('20111019173246');

INSERT INTO schema_migrations (version) VALUES ('20111020160644');

INSERT INTO schema_migrations (version) VALUES ('20111021164945');

INSERT INTO schema_migrations (version) VALUES ('20111022170400');

INSERT INTO schema_migrations (version) VALUES ('20111023154034');

INSERT INTO schema_migrations (version) VALUES ('20111023154130');

INSERT INTO schema_migrations (version) VALUES ('20111023195205');

INSERT INTO schema_migrations (version) VALUES ('20111026135125');

INSERT INTO schema_migrations (version) VALUES ('20111026152530');

INSERT INTO schema_migrations (version) VALUES ('20111026200223');

INSERT INTO schema_migrations (version) VALUES ('20111027230610');

INSERT INTO schema_migrations (version) VALUES ('20111028070604');

INSERT INTO schema_migrations (version) VALUES ('20111029135514');

INSERT INTO schema_migrations (version) VALUES ('20111029150934');

INSERT INTO schema_migrations (version) VALUES ('20111107211538');

INSERT INTO schema_migrations (version) VALUES ('20111111184657');

INSERT INTO schema_migrations (version) VALUES ('20111116140040');

INSERT INTO schema_migrations (version) VALUES ('20111122232244');

INSERT INTO schema_migrations (version) VALUES ('20111123160010');

INSERT INTO schema_migrations (version) VALUES ('20111128140341');

INSERT INTO schema_migrations (version) VALUES ('20111130181101');

INSERT INTO schema_migrations (version) VALUES ('20111216134039');

INSERT INTO schema_migrations (version) VALUES ('20111216140849');

INSERT INTO schema_migrations (version) VALUES ('20111219073859');

INSERT INTO schema_migrations (version) VALUES ('20111220152347');

INSERT INTO schema_migrations (version) VALUES ('20111221120208');

INSERT INTO schema_migrations (version) VALUES ('20111221194422');

INSERT INTO schema_migrations (version) VALUES ('20111226141947');

INSERT INTO schema_migrations (version) VALUES ('20111228182425');

INSERT INTO schema_migrations (version) VALUES ('20120111072106');

INSERT INTO schema_migrations (version) VALUES ('20120111080234');

INSERT INTO schema_migrations (version) VALUES ('20120111135443');

INSERT INTO schema_migrations (version) VALUES ('20120113121748');

INSERT INTO schema_migrations (version) VALUES ('20120113151305');

INSERT INTO schema_migrations (version) VALUES ('20120113212924');

INSERT INTO schema_migrations (version) VALUES ('20120117110723');

INSERT INTO schema_migrations (version) VALUES ('20120117210132');

INSERT INTO schema_migrations (version) VALUES ('20120118173141');

INSERT INTO schema_migrations (version) VALUES ('20120123120400');

INSERT INTO schema_migrations (version) VALUES ('20120123134616');

INSERT INTO schema_migrations (version) VALUES ('20120123161250');

INSERT INTO schema_migrations (version) VALUES ('20120124065207');

INSERT INTO schema_migrations (version) VALUES ('20120124101727');

INSERT INTO schema_migrations (version) VALUES ('20120126214421');

INSERT INTO schema_migrations (version) VALUES ('20120126214447');

INSERT INTO schema_migrations (version) VALUES ('20120127141211');

INSERT INTO schema_migrations (version) VALUES ('20120127234602');

INSERT INTO schema_migrations (version) VALUES ('20120131124517');

INSERT INTO schema_migrations (version) VALUES ('20120131141651');

INSERT INTO schema_migrations (version) VALUES ('20120201181421');

INSERT INTO schema_migrations (version) VALUES ('20120202154114');

INSERT INTO schema_migrations (version) VALUES ('20120206194328');

INSERT INTO schema_migrations (version) VALUES ('20120206225130');

INSERT INTO schema_migrations (version) VALUES ('20120209135822');

INSERT INTO schema_migrations (version) VALUES ('20120210141153');

INSERT INTO schema_migrations (version) VALUES ('20120214021626');

INSERT INTO schema_migrations (version) VALUES ('20120219161749');

INSERT INTO schema_migrations (version) VALUES ('20120220131333');

INSERT INTO schema_migrations (version) VALUES ('20120220175615');

INSERT INTO schema_migrations (version) VALUES ('20120220185458');

INSERT INTO schema_migrations (version) VALUES ('20120224122738');

INSERT INTO schema_migrations (version) VALUES ('20120228094721');

INSERT INTO schema_migrations (version) VALUES ('20120228100121');

INSERT INTO schema_migrations (version) VALUES ('20120229163054');

INSERT INTO schema_migrations (version) VALUES ('20120229182356');

INSERT INTO schema_migrations (version) VALUES ('20120302102734');

INSERT INTO schema_migrations (version) VALUES ('20120302114735');

INSERT INTO schema_migrations (version) VALUES ('20120303062601');

INSERT INTO schema_migrations (version) VALUES ('20120303171802');

INSERT INTO schema_migrations (version) VALUES ('20120306212914');

INSERT INTO schema_migrations (version) VALUES ('20120313130930');

INSERT INTO schema_migrations (version) VALUES ('20120314151558');

INSERT INTO schema_migrations (version) VALUES ('20120314162313');

INSERT INTO schema_migrations (version) VALUES ('20120314223151');

INSERT INTO schema_migrations (version) VALUES ('20120320102912');

INSERT INTO schema_migrations (version) VALUES ('20120321130436');

INSERT INTO schema_migrations (version) VALUES ('20120326142636');

INSERT INTO schema_migrations (version) VALUES ('20120329181830');

INSERT INTO schema_migrations (version) VALUES ('20120329182602');

INSERT INTO schema_migrations (version) VALUES ('20120330201229');

INSERT INTO schema_migrations (version) VALUES ('20120331180541');

INSERT INTO schema_migrations (version) VALUES ('20120403110931');

INSERT INTO schema_migrations (version) VALUES ('20120404134602');

INSERT INTO schema_migrations (version) VALUES ('20120411142354');

INSERT INTO schema_migrations (version) VALUES ('20120412173938');

INSERT INTO schema_migrations (version) VALUES ('20120413102757');

INSERT INTO schema_migrations (version) VALUES ('20120413160722');

INSERT INTO schema_migrations (version) VALUES ('20120417133722');

INSERT INTO schema_migrations (version) VALUES ('20120418100619');

INSERT INTO schema_migrations (version) VALUES ('20120425174830');

INSERT INTO schema_migrations (version) VALUES ('20120425190938');

INSERT INTO schema_migrations (version) VALUES ('20120428053303');

INSERT INTO schema_migrations (version) VALUES ('20120428054604');

INSERT INTO schema_migrations (version) VALUES ('20120428070521');

INSERT INTO schema_migrations (version) VALUES ('20120428105843');

INSERT INTO schema_migrations (version) VALUES ('20120505101650');

INSERT INTO schema_migrations (version) VALUES ('20120512102707');

INSERT INTO schema_migrations (version) VALUES ('20120515095324');

INSERT INTO schema_migrations (version) VALUES ('20120518103340');

INSERT INTO schema_migrations (version) VALUES ('20120518105225');

INSERT INTO schema_migrations (version) VALUES ('20120523113925');

INSERT INTO schema_migrations (version) VALUES ('20120524132504');

INSERT INTO schema_migrations (version) VALUES ('20120529130537');

INSERT INTO schema_migrations (version) VALUES ('20120601142035');

INSERT INTO schema_migrations (version) VALUES ('20120607153342');

INSERT INTO schema_migrations (version) VALUES ('20120609163454');

INSERT INTO schema_migrations (version) VALUES ('20120622092725');

INSERT INTO schema_migrations (version) VALUES ('20120627101821');

INSERT INTO schema_migrations (version) VALUES ('20120628142723');

INSERT INTO schema_migrations (version) VALUES ('20120628165702');

INSERT INTO schema_migrations (version) VALUES ('20120629134216');

INSERT INTO schema_migrations (version) VALUES ('20120703101719');

INSERT INTO schema_migrations (version) VALUES ('20120710134434');

INSERT INTO schema_migrations (version) VALUES ('20120719045806');

INSERT INTO schema_migrations (version) VALUES ('20120727141521');

INSERT INTO schema_migrations (version) VALUES ('20120730150317');

INSERT INTO schema_migrations (version) VALUES ('20120730185119');

INSERT INTO schema_migrations (version) VALUES ('20120730214052');

INSERT INTO schema_migrations (version) VALUES ('20120822130632');

INSERT INTO schema_migrations (version) VALUES ('20120822210712');

INSERT INTO schema_migrations (version) VALUES ('20120906115648');

INSERT INTO schema_migrations (version) VALUES ('20120910094748');

INSERT INTO schema_migrations (version) VALUES ('20120914160741');

INSERT INTO schema_migrations (version) VALUES ('20121003081546');

INSERT INTO schema_migrations (version) VALUES ('20121003154246');

INSERT INTO schema_migrations (version) VALUES ('20121005100158');

INSERT INTO schema_migrations (version) VALUES ('20121027084602');

INSERT INTO schema_migrations (version) VALUES ('20121106113338');

INSERT INTO schema_migrations (version) VALUES ('20121127122032');

INSERT INTO schema_migrations (version) VALUES ('20121203142727');

INSERT INTO schema_migrations (version) VALUES ('20121206143724');

INSERT INTO schema_migrations (version) VALUES ('20121211121412');

INSERT INTO schema_migrations (version) VALUES ('20121211132948');

INSERT INTO schema_migrations (version) VALUES ('20121214145009');

INSERT INTO schema_migrations (version) VALUES ('20121219122905');