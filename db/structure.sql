SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: brimming; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS brimming;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: questions_search_vector_update(); Type: FUNCTION; Schema: brimming; Owner: -
--

CREATE FUNCTION brimming.questions_search_vector_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        answer_text TEXT;
      BEGIN
        -- Aggregate all answer bodies for this question
        SELECT COALESCE(string_agg(body, ' '), '')
        INTO answer_text
        FROM answers
        WHERE question_id = NEW.id AND deleted_at IS NULL;

        -- Build the search vector with weights:
        -- A = title (highest weight)
        -- B = question body
        -- C = answer content
        NEW.search_vector :=
          setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
          setweight(to_tsvector('english', COALESCE(NEW.body, '')), 'B') ||
          setweight(to_tsvector('english', answer_text), 'C');

        RETURN NEW;
      END;
      $$;



--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';



--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.active_storage_attachments_id_seq OWNED BY brimming.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.active_storage_blobs_id_seq OWNED BY brimming.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.active_storage_variant_records_id_seq OWNED BY brimming.active_storage_variant_records.id;


--
-- Name: answers; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.answers (
    id bigint NOT NULL,
    body text NOT NULL,
    user_id bigint NOT NULL,
    question_id bigint NOT NULL,
    is_correct boolean DEFAULT false NOT NULL,
    vote_score integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    edited_at timestamp(6) without time zone,
    last_editor_id bigint,
    deleted_at timestamp(6) without time zone,
    sponsored_by_id bigint
);


--
-- Name: answers_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: answers_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.answers_id_seq OWNED BY brimming.answers.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: article_spaces; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.article_spaces (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    space_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: article_spaces_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.article_spaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: article_spaces_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.article_spaces_id_seq OWNED BY brimming.article_spaces.id;


--
-- Name: article_votes; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.article_votes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    article_id bigint NOT NULL,
    value integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: article_votes_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.article_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: article_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.article_votes_id_seq OWNED BY brimming.article_votes.id;


--
-- Name: articles; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.articles (
    id bigint NOT NULL,
    title character varying NOT NULL,
    body text,
    content_type character varying DEFAULT 'markdown'::character varying NOT NULL,
    context text,
    user_id bigint NOT NULL,
    last_editor_id bigint,
    edited_at timestamp(6) without time zone,
    slug character varying NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedded_at timestamp(6) without time zone,
    vote_score integer DEFAULT 0 NOT NULL,
    views_count integer DEFAULT 0 NOT NULL
);


--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.articles_id_seq OWNED BY brimming.articles.id;


--
-- Name: bookmarks; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.bookmarks (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    bookmarkable_type character varying NOT NULL,
    bookmarkable_id bigint NOT NULL,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bookmarks_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.bookmarks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.bookmarks_id_seq OWNED BY brimming.bookmarks.id;


--
-- Name: chunks; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.chunks (
    id bigint NOT NULL,
    chunkable_type character varying NOT NULL,
    chunkable_id bigint NOT NULL,
    chunk_index integer DEFAULT 0 NOT NULL,
    content text NOT NULL,
    token_count integer,
    embedding public.vector,
    embedded_at timestamp(6) without time zone,
    embedding_provider_id bigint,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chunks_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.chunks_id_seq OWNED BY brimming.chunks.id;


--
-- Name: comment_votes; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.comment_votes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    comment_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comment_votes_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.comment_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.comment_votes_id_seq OWNED BY brimming.comment_votes.id;


--
-- Name: comments; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.comments (
    id bigint NOT NULL,
    body text NOT NULL,
    user_id bigint NOT NULL,
    commentable_type character varying NOT NULL,
    commentable_id bigint NOT NULL,
    parent_comment_id bigint,
    vote_score integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    edited_at timestamp(6) without time zone,
    last_editor_id bigint,
    deleted_at timestamp(6) without time zone
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.comments_id_seq OWNED BY brimming.comments.id;


--
-- Name: embedding_providers; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.embedding_providers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    provider_type character varying NOT NULL,
    api_key character varying,
    api_endpoint character varying,
    embedding_model character varying NOT NULL,
    dimensions integer NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: embedding_providers_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.embedding_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: embedding_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.embedding_providers_id_seq OWNED BY brimming.embedding_providers.id;


--
-- Name: faq_suggestions; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.faq_suggestions (
    id bigint NOT NULL,
    space_id bigint NOT NULL,
    created_by_id bigint NOT NULL,
    batch_id uuid NOT NULL,
    source_type character varying NOT NULL,
    source_context text,
    question_text character varying NOT NULL,
    answer_text text NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    question_body text
);


--
-- Name: faq_suggestions_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.faq_suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.faq_suggestions_id_seq OWNED BY brimming.faq_suggestions.id;


--
-- Name: ldap_group_mapping_spaces; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.ldap_group_mapping_spaces (
    id bigint NOT NULL,
    ldap_group_mapping_id bigint NOT NULL,
    space_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ldap_group_mapping_spaces_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.ldap_group_mapping_spaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ldap_group_mapping_spaces_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.ldap_group_mapping_spaces_id_seq OWNED BY brimming.ldap_group_mapping_spaces.id;


--
-- Name: ldap_group_mappings; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.ldap_group_mappings (
    id bigint NOT NULL,
    ldap_server_id bigint NOT NULL,
    group_pattern character varying NOT NULL,
    pattern_type character varying DEFAULT 'exact'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ldap_group_mappings_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.ldap_group_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ldap_group_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.ldap_group_mappings_id_seq OWNED BY brimming.ldap_group_mappings.id;


--
-- Name: ldap_servers; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.ldap_servers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    host character varying NOT NULL,
    port integer DEFAULT 389 NOT NULL,
    encryption character varying DEFAULT 'plain'::character varying NOT NULL,
    bind_dn character varying,
    bind_password character varying,
    user_search_base character varying NOT NULL,
    user_search_filter character varying DEFAULT '(uid=%{username})'::character varying,
    group_search_base character varying,
    group_search_filter character varying DEFAULT '(member=%{dn})'::character varying,
    uid_attribute character varying DEFAULT 'uid'::character varying NOT NULL,
    email_attribute character varying DEFAULT 'mail'::character varying NOT NULL,
    name_attribute character varying DEFAULT 'cn'::character varying,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ldap_servers_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.ldap_servers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ldap_servers_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.ldap_servers_id_seq OWNED BY brimming.ldap_servers.id;


--
-- Name: llm_providers; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.llm_providers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    provider_type character varying NOT NULL,
    api_key character varying,
    api_endpoint character varying,
    llm_model character varying NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: llm_providers_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.llm_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: llm_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.llm_providers_id_seq OWNED BY brimming.llm_providers.id;


--
-- Name: question_sources; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.question_sources (
    id bigint NOT NULL,
    question_id bigint NOT NULL,
    source_type character varying NOT NULL,
    source_id bigint,
    source_excerpt text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_sources_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.question_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.question_sources_id_seq OWNED BY brimming.question_sources.id;


--
-- Name: question_tags; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.question_tags (
    id bigint NOT NULL,
    question_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_tags_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.question_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.question_tags_id_seq OWNED BY brimming.question_tags.id;


--
-- Name: question_votes; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.question_votes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    question_id bigint NOT NULL,
    value integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: question_votes_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.question_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.question_votes_id_seq OWNED BY brimming.question_votes.id;


--
-- Name: questions; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.questions (
    id bigint NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    user_id bigint NOT NULL,
    space_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    edited_at timestamp(6) without time zone,
    last_editor_id bigint,
    views_count integer DEFAULT 0 NOT NULL,
    vote_score integer DEFAULT 0 NOT NULL,
    deleted_at timestamp(6) without time zone,
    slug character varying,
    embedded_at timestamp(6) without time zone,
    search_vector tsvector,
    sponsored_by_id bigint
);


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.questions_id_seq OWNED BY brimming.questions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: search_settings; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.search_settings (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value text NOT NULL,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: search_settings_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.search_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.search_settings_id_seq OWNED BY brimming.search_settings.id;


--
-- Name: space_moderators; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.space_moderators (
    id bigint NOT NULL,
    space_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: space_moderators_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.space_moderators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: space_moderators_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.space_moderators_id_seq OWNED BY brimming.space_moderators.id;


--
-- Name: space_opt_outs; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.space_opt_outs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    space_id bigint NOT NULL,
    ldap_group_mapping_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: space_opt_outs_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.space_opt_outs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: space_opt_outs_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.space_opt_outs_id_seq OWNED BY brimming.space_opt_outs.id;


--
-- Name: space_publishers; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.space_publishers (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    space_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: space_publishers_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.space_publishers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: space_publishers_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.space_publishers_id_seq OWNED BY brimming.space_publishers.id;


--
-- Name: space_subscriptions; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.space_subscriptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    space_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: space_subscriptions_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.space_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: space_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.space_subscriptions_id_seq OWNED BY brimming.space_subscriptions.id;


--
-- Name: spaces; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.spaces (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    qa_wizard_prompt text,
    rag_chunk_limit integer,
    similar_questions_limit integer
);


--
-- Name: spaces_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.spaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spaces_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.spaces_id_seq OWNED BY brimming.spaces.id;


--
-- Name: tags; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.tags (
    id bigint NOT NULL,
    space_id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    questions_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.tags_id_seq OWNED BY brimming.tags.id;


--
-- Name: user_emails; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.user_emails (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    email character varying NOT NULL,
    "primary" boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    verified_at timestamp(6) without time zone,
    verification_token character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_emails_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.user_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.user_emails_id_seq OWNED BY brimming.user_emails.id;


--
-- Name: users; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.users (
    id bigint NOT NULL,
    email character varying NOT NULL,
    username character varying NOT NULL,
    avatar_url character varying,
    role integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    full_name character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    provider character varying,
    uid character varying,
    ldap_dn character varying,
    timezone character varying DEFAULT 'UTC'::character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.users_id_seq OWNED BY brimming.users.id;


--
-- Name: votes; Type: TABLE; Schema: brimming; Owner: -
--

CREATE TABLE brimming.votes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    answer_id bigint NOT NULL,
    value integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: votes_id_seq; Type: SEQUENCE; Schema: brimming; Owner: -
--

CREATE SEQUENCE brimming.votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_id_seq; Type: SEQUENCE OWNED BY; Schema: brimming; Owner: -
--

ALTER SEQUENCE brimming.votes_id_seq OWNED BY brimming.votes.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('brimming.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('brimming.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('brimming.active_storage_variant_records_id_seq'::regclass);


--
-- Name: answers id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.answers ALTER COLUMN id SET DEFAULT nextval('brimming.answers_id_seq'::regclass);


--
-- Name: article_spaces id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_spaces ALTER COLUMN id SET DEFAULT nextval('brimming.article_spaces_id_seq'::regclass);


--
-- Name: article_votes id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_votes ALTER COLUMN id SET DEFAULT nextval('brimming.article_votes_id_seq'::regclass);


--
-- Name: articles id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.articles ALTER COLUMN id SET DEFAULT nextval('brimming.articles_id_seq'::regclass);


--
-- Name: bookmarks id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.bookmarks ALTER COLUMN id SET DEFAULT nextval('brimming.bookmarks_id_seq'::regclass);


--
-- Name: chunks id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.chunks ALTER COLUMN id SET DEFAULT nextval('brimming.chunks_id_seq'::regclass);


--
-- Name: comment_votes id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comment_votes ALTER COLUMN id SET DEFAULT nextval('brimming.comment_votes_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comments ALTER COLUMN id SET DEFAULT nextval('brimming.comments_id_seq'::regclass);


--
-- Name: embedding_providers id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.embedding_providers ALTER COLUMN id SET DEFAULT nextval('brimming.embedding_providers_id_seq'::regclass);


--
-- Name: faq_suggestions id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.faq_suggestions ALTER COLUMN id SET DEFAULT nextval('brimming.faq_suggestions_id_seq'::regclass);


--
-- Name: ldap_group_mapping_spaces id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mapping_spaces ALTER COLUMN id SET DEFAULT nextval('brimming.ldap_group_mapping_spaces_id_seq'::regclass);


--
-- Name: ldap_group_mappings id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mappings ALTER COLUMN id SET DEFAULT nextval('brimming.ldap_group_mappings_id_seq'::regclass);


--
-- Name: ldap_servers id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_servers ALTER COLUMN id SET DEFAULT nextval('brimming.ldap_servers_id_seq'::regclass);


--
-- Name: llm_providers id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.llm_providers ALTER COLUMN id SET DEFAULT nextval('brimming.llm_providers_id_seq'::regclass);


--
-- Name: question_sources id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_sources ALTER COLUMN id SET DEFAULT nextval('brimming.question_sources_id_seq'::regclass);


--
-- Name: question_tags id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_tags ALTER COLUMN id SET DEFAULT nextval('brimming.question_tags_id_seq'::regclass);


--
-- Name: question_votes id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_votes ALTER COLUMN id SET DEFAULT nextval('brimming.question_votes_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.questions ALTER COLUMN id SET DEFAULT nextval('brimming.questions_id_seq'::regclass);


--
-- Name: search_settings id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.search_settings ALTER COLUMN id SET DEFAULT nextval('brimming.search_settings_id_seq'::regclass);


--
-- Name: space_moderators id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_moderators ALTER COLUMN id SET DEFAULT nextval('brimming.space_moderators_id_seq'::regclass);


--
-- Name: space_opt_outs id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_opt_outs ALTER COLUMN id SET DEFAULT nextval('brimming.space_opt_outs_id_seq'::regclass);


--
-- Name: space_publishers id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_publishers ALTER COLUMN id SET DEFAULT nextval('brimming.space_publishers_id_seq'::regclass);


--
-- Name: space_subscriptions id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_subscriptions ALTER COLUMN id SET DEFAULT nextval('brimming.space_subscriptions_id_seq'::regclass);


--
-- Name: spaces id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.spaces ALTER COLUMN id SET DEFAULT nextval('brimming.spaces_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.tags ALTER COLUMN id SET DEFAULT nextval('brimming.tags_id_seq'::regclass);


--
-- Name: user_emails id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.user_emails ALTER COLUMN id SET DEFAULT nextval('brimming.user_emails_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.users ALTER COLUMN id SET DEFAULT nextval('brimming.users_id_seq'::regclass);


--
-- Name: votes id; Type: DEFAULT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.votes ALTER COLUMN id SET DEFAULT nextval('brimming.votes_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: answers answers_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.answers
    ADD CONSTRAINT answers_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: article_spaces article_spaces_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_spaces
    ADD CONSTRAINT article_spaces_pkey PRIMARY KEY (id);


--
-- Name: article_votes article_votes_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_votes
    ADD CONSTRAINT article_votes_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (id);


--
-- Name: chunks chunks_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.chunks
    ADD CONSTRAINT chunks_pkey PRIMARY KEY (id);


--
-- Name: comment_votes comment_votes_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comment_votes
    ADD CONSTRAINT comment_votes_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: embedding_providers embedding_providers_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.embedding_providers
    ADD CONSTRAINT embedding_providers_pkey PRIMARY KEY (id);


--
-- Name: faq_suggestions faq_suggestions_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.faq_suggestions
    ADD CONSTRAINT faq_suggestions_pkey PRIMARY KEY (id);


--
-- Name: ldap_group_mapping_spaces ldap_group_mapping_spaces_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mapping_spaces
    ADD CONSTRAINT ldap_group_mapping_spaces_pkey PRIMARY KEY (id);


--
-- Name: ldap_group_mappings ldap_group_mappings_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mappings
    ADD CONSTRAINT ldap_group_mappings_pkey PRIMARY KEY (id);


--
-- Name: ldap_servers ldap_servers_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_servers
    ADD CONSTRAINT ldap_servers_pkey PRIMARY KEY (id);


--
-- Name: llm_providers llm_providers_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.llm_providers
    ADD CONSTRAINT llm_providers_pkey PRIMARY KEY (id);


--
-- Name: question_sources question_sources_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_sources
    ADD CONSTRAINT question_sources_pkey PRIMARY KEY (id);


--
-- Name: question_tags question_tags_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_tags
    ADD CONSTRAINT question_tags_pkey PRIMARY KEY (id);


--
-- Name: question_votes question_votes_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_votes
    ADD CONSTRAINT question_votes_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: search_settings search_settings_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.search_settings
    ADD CONSTRAINT search_settings_pkey PRIMARY KEY (id);


--
-- Name: space_moderators space_moderators_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_moderators
    ADD CONSTRAINT space_moderators_pkey PRIMARY KEY (id);


--
-- Name: space_opt_outs space_opt_outs_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_opt_outs
    ADD CONSTRAINT space_opt_outs_pkey PRIMARY KEY (id);


--
-- Name: space_publishers space_publishers_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_publishers
    ADD CONSTRAINT space_publishers_pkey PRIMARY KEY (id);


--
-- Name: space_subscriptions space_subscriptions_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_subscriptions
    ADD CONSTRAINT space_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: user_emails user_emails_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.user_emails
    ADD CONSTRAINT user_emails_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: idx_ldap_group_mapping_spaces_unique; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX idx_ldap_group_mapping_spaces_unique ON brimming.ldap_group_mapping_spaces USING btree (ldap_group_mapping_id, space_id);


--
-- Name: idx_space_opt_outs_unique; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX idx_space_opt_outs_unique ON brimming.space_opt_outs USING btree (user_id, space_id, ldap_group_mapping_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON brimming.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON brimming.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON brimming.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON brimming.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_answers_on_last_editor_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_last_editor_id ON brimming.answers USING btree (last_editor_id);


--
-- Name: index_answers_on_question_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_question_id ON brimming.answers USING btree (question_id);


--
-- Name: index_answers_on_question_id_and_is_correct; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_question_id_and_is_correct ON brimming.answers USING btree (question_id, is_correct);


--
-- Name: index_answers_on_question_id_and_vote_score; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_question_id_and_vote_score ON brimming.answers USING btree (question_id, vote_score);


--
-- Name: index_answers_on_sponsored_by_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_sponsored_by_id ON brimming.answers USING btree (sponsored_by_id);


--
-- Name: index_answers_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_user_id ON brimming.answers USING btree (user_id);


--
-- Name: index_answers_on_vote_score; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_answers_on_vote_score ON brimming.answers USING btree (vote_score);


--
-- Name: index_article_spaces_on_article_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_article_spaces_on_article_id ON brimming.article_spaces USING btree (article_id);


--
-- Name: index_article_spaces_on_article_id_and_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_article_spaces_on_article_id_and_space_id ON brimming.article_spaces USING btree (article_id, space_id);


--
-- Name: index_article_spaces_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_article_spaces_on_space_id ON brimming.article_spaces USING btree (space_id);


--
-- Name: index_article_votes_on_article_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_article_votes_on_article_id ON brimming.article_votes USING btree (article_id);


--
-- Name: index_article_votes_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_article_votes_on_user_id ON brimming.article_votes USING btree (user_id);


--
-- Name: index_article_votes_on_user_id_and_article_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_article_votes_on_user_id_and_article_id ON brimming.article_votes USING btree (user_id, article_id);


--
-- Name: index_articles_on_content_type; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_content_type ON brimming.articles USING btree (content_type);


--
-- Name: index_articles_on_deleted_at; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_deleted_at ON brimming.articles USING btree (deleted_at);


--
-- Name: index_articles_on_embedded_at; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_embedded_at ON brimming.articles USING btree (embedded_at);


--
-- Name: index_articles_on_last_editor_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_last_editor_id ON brimming.articles USING btree (last_editor_id);


--
-- Name: index_articles_on_slug; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_articles_on_slug ON brimming.articles USING btree (slug);


--
-- Name: index_articles_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_user_id ON brimming.articles USING btree (user_id);


--
-- Name: index_articles_on_views_count; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_views_count ON brimming.articles USING btree (views_count);


--
-- Name: index_articles_on_vote_score; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_articles_on_vote_score ON brimming.articles USING btree (vote_score);


--
-- Name: index_bookmarks_on_bookmarkable; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_bookmarks_on_bookmarkable ON brimming.bookmarks USING btree (bookmarkable_type, bookmarkable_id);


--
-- Name: index_bookmarks_on_user_and_bookmarkable; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_bookmarks_on_user_and_bookmarkable ON brimming.bookmarks USING btree (user_id, bookmarkable_type, bookmarkable_id);


--
-- Name: index_bookmarks_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_bookmarks_on_user_id ON brimming.bookmarks USING btree (user_id);


--
-- Name: index_chunks_on_chunkable; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_chunks_on_chunkable ON brimming.chunks USING btree (chunkable_type, chunkable_id);


--
-- Name: index_chunks_on_chunkable_and_index; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_chunks_on_chunkable_and_index ON brimming.chunks USING btree (chunkable_type, chunkable_id, chunk_index);


--
-- Name: index_chunks_on_embedding_provider_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_chunks_on_embedding_provider_id ON brimming.chunks USING btree (embedding_provider_id);


--
-- Name: index_chunks_on_unembedded; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_chunks_on_unembedded ON brimming.chunks USING btree (embedded_at) WHERE (embedded_at IS NULL);


--
-- Name: index_comment_votes_on_comment_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comment_votes_on_comment_id ON brimming.comment_votes USING btree (comment_id);


--
-- Name: index_comment_votes_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comment_votes_on_user_id ON brimming.comment_votes USING btree (user_id);


--
-- Name: index_comment_votes_on_user_id_and_comment_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_comment_votes_on_user_id_and_comment_id ON brimming.comment_votes USING btree (user_id, comment_id);


--
-- Name: index_comments_on_commentable; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comments_on_commentable ON brimming.comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_commentable_and_created_at; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comments_on_commentable_and_created_at ON brimming.comments USING btree (commentable_type, commentable_id, created_at);


--
-- Name: index_comments_on_last_editor_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comments_on_last_editor_id ON brimming.comments USING btree (last_editor_id);


--
-- Name: index_comments_on_parent_comment_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comments_on_parent_comment_id ON brimming.comments USING btree (parent_comment_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_comments_on_user_id ON brimming.comments USING btree (user_id);


--
-- Name: index_embedding_providers_on_enabled; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_embedding_providers_on_enabled ON brimming.embedding_providers USING btree (enabled);


--
-- Name: index_embedding_providers_on_provider_type; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_embedding_providers_on_provider_type ON brimming.embedding_providers USING btree (provider_type);


--
-- Name: index_faq_suggestions_on_batch_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_faq_suggestions_on_batch_id ON brimming.faq_suggestions USING btree (batch_id);


--
-- Name: index_faq_suggestions_on_created_at; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_faq_suggestions_on_created_at ON brimming.faq_suggestions USING btree (created_at);


--
-- Name: index_faq_suggestions_on_created_by_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_faq_suggestions_on_created_by_id ON brimming.faq_suggestions USING btree (created_by_id);


--
-- Name: index_faq_suggestions_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_faq_suggestions_on_space_id ON brimming.faq_suggestions USING btree (space_id);


--
-- Name: index_faq_suggestions_on_space_id_and_status; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_faq_suggestions_on_space_id_and_status ON brimming.faq_suggestions USING btree (space_id, status);


--
-- Name: index_faq_suggestions_on_status; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_faq_suggestions_on_status ON brimming.faq_suggestions USING btree (status);


--
-- Name: index_ldap_group_mapping_spaces_on_ldap_group_mapping_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_ldap_group_mapping_spaces_on_ldap_group_mapping_id ON brimming.ldap_group_mapping_spaces USING btree (ldap_group_mapping_id);


--
-- Name: index_ldap_group_mapping_spaces_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_ldap_group_mapping_spaces_on_space_id ON brimming.ldap_group_mapping_spaces USING btree (space_id);


--
-- Name: index_ldap_group_mappings_on_ldap_server_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_ldap_group_mappings_on_ldap_server_id ON brimming.ldap_group_mappings USING btree (ldap_server_id);


--
-- Name: index_ldap_group_mappings_on_ldap_server_id_and_group_pattern; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_ldap_group_mappings_on_ldap_server_id_and_group_pattern ON brimming.ldap_group_mappings USING btree (ldap_server_id, group_pattern);


--
-- Name: index_ldap_servers_on_enabled; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_ldap_servers_on_enabled ON brimming.ldap_servers USING btree (enabled);


--
-- Name: index_ldap_servers_on_name; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_ldap_servers_on_name ON brimming.ldap_servers USING btree (name);


--
-- Name: index_llm_providers_on_enabled; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_llm_providers_on_enabled ON brimming.llm_providers USING btree (enabled);


--
-- Name: index_llm_providers_on_is_default; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_llm_providers_on_is_default ON brimming.llm_providers USING btree (is_default);


--
-- Name: index_llm_providers_on_name; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_llm_providers_on_name ON brimming.llm_providers USING btree (name);


--
-- Name: index_llm_providers_on_provider_type; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_llm_providers_on_provider_type ON brimming.llm_providers USING btree (provider_type);


--
-- Name: index_question_sources_on_question_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_question_sources_on_question_id ON brimming.question_sources USING btree (question_id);


--
-- Name: index_question_sources_on_source_type_and_source_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_question_sources_on_source_type_and_source_id ON brimming.question_sources USING btree (source_type, source_id);


--
-- Name: index_question_tags_on_question_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_question_tags_on_question_id ON brimming.question_tags USING btree (question_id);


--
-- Name: index_question_tags_on_question_id_and_tag_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_question_tags_on_question_id_and_tag_id ON brimming.question_tags USING btree (question_id, tag_id);


--
-- Name: index_question_tags_on_tag_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_question_tags_on_tag_id ON brimming.question_tags USING btree (tag_id);


--
-- Name: index_question_votes_on_question_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_question_votes_on_question_id ON brimming.question_votes USING btree (question_id);


--
-- Name: index_question_votes_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_question_votes_on_user_id ON brimming.question_votes USING btree (user_id);


--
-- Name: index_question_votes_on_user_id_and_question_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_question_votes_on_user_id_and_question_id ON brimming.question_votes USING btree (user_id, question_id);


--
-- Name: index_questions_on_created_at; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_created_at ON brimming.questions USING btree (created_at);


--
-- Name: index_questions_on_last_editor_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_last_editor_id ON brimming.questions USING btree (last_editor_id);


--
-- Name: index_questions_on_search_vector; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_search_vector ON brimming.questions USING gin (search_vector);


--
-- Name: index_questions_on_slug; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_questions_on_slug ON brimming.questions USING btree (slug);


--
-- Name: index_questions_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_space_id ON brimming.questions USING btree (space_id);


--
-- Name: index_questions_on_space_id_and_created_at; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_space_id_and_created_at ON brimming.questions USING btree (space_id, created_at);


--
-- Name: index_questions_on_sponsored_by_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_sponsored_by_id ON brimming.questions USING btree (sponsored_by_id);


--
-- Name: index_questions_on_title_trgm; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_title_trgm ON brimming.questions USING gin (title public.gin_trgm_ops);


--
-- Name: index_questions_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_user_id ON brimming.questions USING btree (user_id);


--
-- Name: index_questions_on_views_count; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_views_count ON brimming.questions USING btree (views_count);


--
-- Name: index_questions_on_vote_score; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_questions_on_vote_score ON brimming.questions USING btree (vote_score);


--
-- Name: index_search_settings_on_key; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_search_settings_on_key ON brimming.search_settings USING btree (key);


--
-- Name: index_space_moderators_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_moderators_on_space_id ON brimming.space_moderators USING btree (space_id);


--
-- Name: index_space_moderators_on_space_id_and_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_space_moderators_on_space_id_and_user_id ON brimming.space_moderators USING btree (space_id, user_id);


--
-- Name: index_space_moderators_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_moderators_on_user_id ON brimming.space_moderators USING btree (user_id);


--
-- Name: index_space_opt_outs_on_ldap_group_mapping_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_opt_outs_on_ldap_group_mapping_id ON brimming.space_opt_outs USING btree (ldap_group_mapping_id);


--
-- Name: index_space_opt_outs_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_opt_outs_on_space_id ON brimming.space_opt_outs USING btree (space_id);


--
-- Name: index_space_opt_outs_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_opt_outs_on_user_id ON brimming.space_opt_outs USING btree (user_id);


--
-- Name: index_space_publishers_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_publishers_on_space_id ON brimming.space_publishers USING btree (space_id);


--
-- Name: index_space_publishers_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_publishers_on_user_id ON brimming.space_publishers USING btree (user_id);


--
-- Name: index_space_publishers_on_user_id_and_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_space_publishers_on_user_id_and_space_id ON brimming.space_publishers USING btree (user_id, space_id);


--
-- Name: index_space_subscriptions_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_subscriptions_on_space_id ON brimming.space_subscriptions USING btree (space_id);


--
-- Name: index_space_subscriptions_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_space_subscriptions_on_user_id ON brimming.space_subscriptions USING btree (user_id);


--
-- Name: index_space_subscriptions_on_user_id_and_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_space_subscriptions_on_user_id_and_space_id ON brimming.space_subscriptions USING btree (user_id, space_id);


--
-- Name: index_spaces_on_name; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_spaces_on_name ON brimming.spaces USING btree (name);


--
-- Name: index_spaces_on_slug; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_spaces_on_slug ON brimming.spaces USING btree (slug);


--
-- Name: index_tags_on_space_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_tags_on_space_id ON brimming.tags USING btree (space_id);


--
-- Name: index_tags_on_space_id_and_name; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_space_id_and_name ON brimming.tags USING btree (space_id, name);


--
-- Name: index_tags_on_space_id_and_questions_count; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_tags_on_space_id_and_questions_count ON brimming.tags USING btree (space_id, questions_count);


--
-- Name: index_tags_on_space_id_and_slug; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_space_id_and_slug ON brimming.tags USING btree (space_id, slug);


--
-- Name: index_user_emails_on_email; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_user_emails_on_email ON brimming.user_emails USING btree (email);


--
-- Name: index_user_emails_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_user_emails_on_user_id ON brimming.user_emails USING btree (user_id);


--
-- Name: index_user_emails_on_user_id_and_primary; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_user_emails_on_user_id_and_primary ON brimming.user_emails USING btree (user_id, "primary") WHERE ("primary" = true);


--
-- Name: index_user_emails_on_verification_token; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_user_emails_on_verification_token ON brimming.user_emails USING btree (verification_token) WHERE (verification_token IS NOT NULL);


--
-- Name: index_users_on_email; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON brimming.users USING btree (email);


--
-- Name: index_users_on_provider_and_uid; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_users_on_provider_and_uid ON brimming.users USING btree (provider, uid);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON brimming.users USING btree (reset_password_token);


--
-- Name: index_users_on_role; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_users_on_role ON brimming.users USING btree (role);


--
-- Name: index_users_on_username; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON brimming.users USING btree (username);


--
-- Name: index_votes_on_answer_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_votes_on_answer_id ON brimming.votes USING btree (answer_id);


--
-- Name: index_votes_on_user_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE INDEX index_votes_on_user_id ON brimming.votes USING btree (user_id);


--
-- Name: index_votes_on_user_id_and_answer_id; Type: INDEX; Schema: brimming; Owner: -
--

CREATE UNIQUE INDEX index_votes_on_user_id_and_answer_id ON brimming.votes USING btree (user_id, answer_id);


--
-- Name: questions questions_search_vector_trigger; Type: TRIGGER; Schema: brimming; Owner: -
--

CREATE TRIGGER questions_search_vector_trigger BEFORE INSERT OR UPDATE OF title, body ON brimming.questions FOR EACH ROW EXECUTE FUNCTION brimming.questions_search_vector_update();


--
-- Name: space_opt_outs fk_rails_01d8d03183; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_opt_outs
    ADD CONSTRAINT fk_rails_01d8d03183 FOREIGN KEY (ldap_group_mapping_id) REFERENCES brimming.ldap_group_mappings(id);


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: questions fk_rails_047ab75908; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.questions
    ADD CONSTRAINT fk_rails_047ab75908 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: chunks fk_rails_0764725055; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.chunks
    ADD CONSTRAINT fk_rails_0764725055 FOREIGN KEY (embedding_provider_id) REFERENCES brimming.embedding_providers(id);


--
-- Name: comment_votes fk_rails_0873e64a40; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comment_votes
    ADD CONSTRAINT fk_rails_0873e64a40 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: space_publishers fk_rails_0c8fda2cff; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_publishers
    ADD CONSTRAINT fk_rails_0c8fda2cff FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: faq_suggestions fk_rails_0f0f091645; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.faq_suggestions
    ADD CONSTRAINT fk_rails_0f0f091645 FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: questions fk_rails_212c46f0cf; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.questions
    ADD CONSTRAINT fk_rails_212c46f0cf FOREIGN KEY (sponsored_by_id) REFERENCES brimming.users(id);


--
-- Name: space_opt_outs fk_rails_26f203c08a; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_opt_outs
    ADD CONSTRAINT fk_rails_26f203c08a FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: tags fk_rails_2ba41a842b; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.tags
    ADD CONSTRAINT fk_rails_2ba41a842b FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: article_spaces fk_rails_2c1cf7a065; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_spaces
    ADD CONSTRAINT fk_rails_2c1cf7a065 FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: question_sources fk_rails_2d0496b581; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_sources
    ADD CONSTRAINT fk_rails_2d0496b581 FOREIGN KEY (question_id) REFERENCES brimming.questions(id);


--
-- Name: space_moderators fk_rails_31a1760159; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_moderators
    ADD CONSTRAINT fk_rails_31a1760159 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: comments fk_rails_37c4012a7b; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comments
    ADD CONSTRAINT fk_rails_37c4012a7b FOREIGN KEY (last_editor_id) REFERENCES brimming.users(id);


--
-- Name: question_tags fk_rails_38e4cf053b; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_tags
    ADD CONSTRAINT fk_rails_38e4cf053b FOREIGN KEY (tag_id) REFERENCES brimming.tags(id);


--
-- Name: articles fk_rails_3d31dad1cc; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.articles
    ADD CONSTRAINT fk_rails_3d31dad1cc FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: answers fk_rails_3d5ed4418f; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.answers
    ADD CONSTRAINT fk_rails_3d5ed4418f FOREIGN KEY (question_id) REFERENCES brimming.questions(id);


--
-- Name: votes fk_rails_3f8d383c32; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.votes
    ADD CONSTRAINT fk_rails_3f8d383c32 FOREIGN KEY (answer_id) REFERENCES brimming.answers(id);


--
-- Name: user_emails fk_rails_410ac92848; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.user_emails
    ADD CONSTRAINT fk_rails_410ac92848 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: space_opt_outs fk_rails_439b1dd8de; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_opt_outs
    ADD CONSTRAINT fk_rails_439b1dd8de FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: questions fk_rails_45dd7c8945; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.questions
    ADD CONSTRAINT fk_rails_45dd7c8945 FOREIGN KEY (last_editor_id) REFERENCES brimming.users(id);


--
-- Name: article_votes fk_rails_55b11fbcc1; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_votes
    ADD CONSTRAINT fk_rails_55b11fbcc1 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: answers fk_rails_584be190c2; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.answers
    ADD CONSTRAINT fk_rails_584be190c2 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: question_votes fk_rails_7831827660; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_votes
    ADD CONSTRAINT fk_rails_7831827660 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: ldap_group_mappings fk_rails_78acf26747; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mappings
    ADD CONSTRAINT fk_rails_78acf26747 FOREIGN KEY (ldap_server_id) REFERENCES brimming.ldap_servers(id);


--
-- Name: space_subscriptions fk_rails_7a7e32dd86; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_subscriptions
    ADD CONSTRAINT fk_rails_7a7e32dd86 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: space_publishers fk_rails_7f4a5f4968; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_publishers
    ADD CONSTRAINT fk_rails_7f4a5f4968 FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: answers fk_rails_909021630a; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.answers
    ADD CONSTRAINT fk_rails_909021630a FOREIGN KEY (last_editor_id) REFERENCES brimming.users(id);


--
-- Name: question_votes fk_rails_974ab16b14; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_votes
    ADD CONSTRAINT fk_rails_974ab16b14 FOREIGN KEY (question_id) REFERENCES brimming.questions(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES brimming.active_storage_blobs(id);


--
-- Name: article_spaces fk_rails_9ecf1db454; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_spaces
    ADD CONSTRAINT fk_rails_9ecf1db454 FOREIGN KEY (article_id) REFERENCES brimming.articles(id);


--
-- Name: space_moderators fk_rails_9f8cd02312; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_moderators
    ADD CONSTRAINT fk_rails_9f8cd02312 FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: comment_votes fk_rails_a0196e2ef9; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comment_votes
    ADD CONSTRAINT fk_rails_a0196e2ef9 FOREIGN KEY (comment_id) REFERENCES brimming.comments(id);


--
-- Name: bookmarks fk_rails_c1ff6fa4ac; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.bookmarks
    ADD CONSTRAINT fk_rails_c1ff6fa4ac FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES brimming.active_storage_blobs(id);


--
-- Name: votes fk_rails_c9b3bef597; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.votes
    ADD CONSTRAINT fk_rails_c9b3bef597 FOREIGN KEY (user_id) REFERENCES brimming.users(id);


--
-- Name: articles fk_rails_c9c3d9cfd2; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.articles
    ADD CONSTRAINT fk_rails_c9c3d9cfd2 FOREIGN KEY (last_editor_id) REFERENCES brimming.users(id);


--
-- Name: answers fk_rails_cb7553b87f; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.answers
    ADD CONSTRAINT fk_rails_cb7553b87f FOREIGN KEY (sponsored_by_id) REFERENCES brimming.users(id);


--
-- Name: ldap_group_mapping_spaces fk_rails_d2e1539dd0; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mapping_spaces
    ADD CONSTRAINT fk_rails_d2e1539dd0 FOREIGN KEY (ldap_group_mapping_id) REFERENCES brimming.ldap_group_mappings(id);


--
-- Name: questions fk_rails_d2f8aeda0b; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.questions
    ADD CONSTRAINT fk_rails_d2f8aeda0b FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: faq_suggestions fk_rails_d7562f4d05; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.faq_suggestions
    ADD CONSTRAINT fk_rails_d7562f4d05 FOREIGN KEY (created_by_id) REFERENCES brimming.users(id);


--
-- Name: comments fk_rails_da28d53ee7; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.comments
    ADD CONSTRAINT fk_rails_da28d53ee7 FOREIGN KEY (parent_comment_id) REFERENCES brimming.comments(id);


--
-- Name: space_subscriptions fk_rails_dff54ce0e9; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.space_subscriptions
    ADD CONSTRAINT fk_rails_dff54ce0e9 FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- Name: article_votes fk_rails_e1f0730a11; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.article_votes
    ADD CONSTRAINT fk_rails_e1f0730a11 FOREIGN KEY (article_id) REFERENCES brimming.articles(id);


--
-- Name: question_tags fk_rails_e6a38f5c87; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.question_tags
    ADD CONSTRAINT fk_rails_e6a38f5c87 FOREIGN KEY (question_id) REFERENCES brimming.questions(id);


--
-- Name: ldap_group_mapping_spaces fk_rails_ec27669b81; Type: FK CONSTRAINT; Schema: brimming; Owner: -
--

ALTER TABLE ONLY brimming.ldap_group_mapping_spaces
    ADD CONSTRAINT fk_rails_ec27669b81 FOREIGN KEY (space_id) REFERENCES brimming.spaces(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO brimming,public;

INSERT INTO "schema_migrations" (version) VALUES
('20251211035633'),
('20251211023123'),
('20251211023053'),
('20251210190145'),
('20251206210953'),
('20251206210838'),
('20251206195247'),
('20251206190846'),
('20251203222224'),
('20251203133555'),
('20251203132418'),
('20251203132417'),
('20251203132416'),
('20251203132415'),
('20251201230632'),
('20251201230617'),
('20251201215307'),
('20251201214415'),
('20251201011229'),
('20251201005222'),
('20251201004914'),
('20251201001952'),
('20251201000652'),
('20251130184528'),
('20251130184224'),
('20251130163633'),
('20251130150108'),
('20251130145205'),
('20251130020631'),
('20251130020609'),
('20251129220653'),
('20251129200949'),
('20251129200918'),
('20251129200835'),
('20251129200751'),
('20251129200650'),
('20251129191627'),
('20251129172345'),
('20251129172341'),
('20251129141759'),
('20251128010924'),
('20251128000155'),
('20251127234819'),
('20251127233917'),
('20251127232454'),
('20251127232453'),
('20251127232452'),
('20251127232451'),
('20251127232445'),
('20251127180000'),
('20251127175340'),
('20251127175313'),
('20251127175240'),
('20251127175204'),
('20251127175139'),
('20251127175059'),
('20251127175000');

