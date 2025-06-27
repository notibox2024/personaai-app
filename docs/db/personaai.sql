--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5 (Debian 17.5-1.pgdg120+1)

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
-- Name: klb_dev_core_hr; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA klb_dev_core_hr;


ALTER SCHEMA klb_dev_core_hr OWNER TO postgres;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: approve_struct_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.approve_struct_enum AS ENUM (
    'HĐQT',
    'TGD'
);


ALTER TYPE public.approve_struct_enum OWNER TO postgres;

--
-- Name: bloodgroup; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.bloodgroup AS ENUM (
    'A',
    'B',
    'AB',
    'O'
);


ALTER TYPE public.bloodgroup OWNER TO postgres;

--
-- Name: decisioncategory; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.decisioncategory AS ENUM (
    'Thường niên',
    'Chuyên đề',
    'Đột xuất'
);


ALTER TYPE public.decisioncategory OWNER TO postgres;

--
-- Name: education_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.education_level AS ENUM (
    '0/12',
    '1/12',
    '2/12',
    '3/12',
    '4/12',
    '5/12',
    '6/12',
    '7/12',
    '8/12',
    '9/12',
    '10/12',
    '11/12',
    '12/12'
);


ALTER TYPE public.education_level OWNER TO postgres;

--
-- Name: employee_types; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.employee_types AS ENUM (
    '1',
    '2',
    '3'
);


ALTER TYPE public.employee_types OWNER TO postgres;

--
-- Name: TYPE employee_types; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.employee_types IS '
  EmployeeTypes:
    "1" - Quản lý bộ phận,
    "2" - Phó bộ phận,
    "3" - Nhân viên thường
';


--
-- Name: exemplarylevel; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exemplarylevel AS ENUM (
    'Xuất sắc',
    'Giỏi',
    'Khá',
    'Trung bình'
);


ALTER TYPE public.exemplarylevel OWNER TO postgres;

--
-- Name: gender; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gender AS ENUM (
    'Male',
    'Female'
);


ALTER TYPE public.gender OWNER TO postgres;

--
-- Name: healthevaluate; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.healthevaluate AS ENUM (
    'GOOD',
    'NORMAL',
    'BAD'
);


ALTER TYPE public.healthevaluate OWNER TO postgres;

--
-- Name: marital_statuses; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.marital_statuses AS ENUM (
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Separated',
    'Undefined'
);


ALTER TYPE public.marital_statuses OWNER TO postgres;

--
-- Name: permission_scope; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.permission_scope AS ENUM (
    'ALL',
    'OWN',
    'NONE',
    'CUSTOM'
);


ALTER TYPE public.permission_scope OWNER TO postgres;

--
-- Name: projectstatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.projectstatus AS ENUM (
    'SPENDING',
    'ACTIVE',
    'COMPLETED',
    'CANCELLED'
);


ALTER TYPE public.projectstatus OWNER TO postgres;

--
-- Name: rewarddisciplinarytype; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.rewarddisciplinarytype AS ENUM (
    'REWARD',
    'DISCIPLINARY'
);


ALTER TYPE public.rewarddisciplinarytype OWNER TO postgres;

--
-- Name: statusunion; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.statusunion AS ENUM (
    'Đang hoạt động',
    'Đã rời đoàn',
    'Tạm dừng'
);


ALTER TYPE public.statusunion OWNER TO postgres;

--
-- Name: add_error(jsonb, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_error(p_errors jsonb, p_field text, p_message text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p_errors || jsonb_build_object('field', p_field, 'message', p_message);
END;
$$;


ALTER FUNCTION public.add_error(p_errors jsonb, p_field text, p_message text) OWNER TO postgres;

--
-- Name: add_role_permission(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_role_permission(p_role_id integer, p_feature_id integer, p_action_id integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    error_details JSONB := '[]'::JSONB;
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    -- Kiểm tra xem feature_id và action_id có hợp lệ trong bảng feature_action không
    IF NOT EXISTS (
        SELECT 1 
        FROM feature_action 
        WHERE feature_id = p_feature_id 
        AND action_id = p_action_id
    ) THEN
        RETURN jsonb_build_object(
        'code', 400,
        'status', false,
        'message', 'Actions not exits in feature_action'
    );

    END IF;

    -- Nếu hợp lệ, thêm vào bảng role_permission
    INSERT INTO role_permission (role_id, feature_id, action_id)
    VALUES (p_role_id, p_feature_id, p_action_id);
    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Add permission successful'
    );

END;
$$;


ALTER FUNCTION public.add_role_permission(p_role_id integer, p_feature_id integer, p_action_id integer) OWNER TO postgres;

--
-- Name: attachment_add(character varying, character varying, character varying, bigint, character varying, integer[], character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.attachment_add(p_file_url character varying, p_file_name character varying, p_file_type character varying, p_file_size bigint, p_target_table character varying, p_target_ids integer[], p_type character varying, p_note text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_attachment_id INT;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);


    -- Kiểm tra đầu vào
    IF p_file_url IS NULL OR p_file_url = '' THEN
        RETURN QUERY SELECT FALSE, 'File URL không được để trống';
        RETURN;
    END IF;

    IF p_file_name IS NULL OR p_file_name = '' THEN
        RETURN QUERY SELECT FALSE, 'Tên file không được để trống';
        RETURN;
    END IF;

    IF p_file_size < 0 THEN
        RETURN QUERY SELECT FALSE, 'Dung lượng file không được âm';
        RETURN;
    END IF;

    IF p_target_table IS NULL OR p_target_table = '' THEN
        RETURN QUERY SELECT FALSE, 'Tên bảng không được để trống';
        RETURN;
    END IF;

    IF array_length(p_target_ids, 1) IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Mảng ID không được để trống';
        RETURN;
    END IF;

    -- Bắt đầu khối xử lý lỗi
    BEGIN
        -- Thêm metadata vào bảng attachments
        INSERT INTO attachments (
            file_url, file_name, file_type, file_size, created_at
        ) VALUES (
            p_file_url, p_file_name, p_file_type, p_file_size, NOW()
        )
        RETURNING id INTO v_attachment_id;

        -- Thêm các liên kết vào bảng attachment_link mà không sử dụng vòng lặp
        INSERT INTO attachment_link (
            attachment_id, target_table, target_id, type, note, created_at
        )
        SELECT v_attachment_id, p_target_table, unnest(p_target_ids), p_type, p_note, NOW();

        -- Trả về kết quả thành công
        RETURN QUERY SELECT TRUE, 'Thêm file đính kèm thành công';

    EXCEPTION
        WHEN OTHERS THEN
            -- Bắt lỗi và trả về thông báo lỗi
            RETURN QUERY SELECT FALSE, SQLERRM;
    END;
END;
$$;


ALTER FUNCTION public.attachment_add(p_file_url character varying, p_file_name character varying, p_file_type character varying, p_file_size bigint, p_target_table character varying, p_target_ids integer[], p_type character varying, p_note text) OWNER TO postgres;

--
-- Name: attachment_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.attachment_delete(p_attachment_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Kiểm tra xem attachment có tồn tại hay không
    IF NOT EXISTS (SELECT 1 FROM attachments WHERE id = p_attachment_id) THEN
        RETURN jsonb_build_object(
            'code', 404,
            'status', false,
            'message', format('Attachment với id %s không tồn tại', p_attachment_id)
        );
    END IF;

    -- Xóa tất cả các liên kết liên quan trong bảng attachment_link
    DELETE FROM attachment_link WHERE attachment_id = p_attachment_id;

    -- Xóa attachment
    DELETE FROM attachments WHERE id = p_attachment_id;

    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', format('Attachment với id %s đã được xóa thành công', p_attachment_id)
    );
END;
$$;


ALTER FUNCTION public.attachment_delete(p_attachment_id integer) OWNER TO postgres;

--
-- Name: attachment_os_add(character varying, integer[], jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.attachment_os_add(p_target_table character varying, p_target_ids integer[], p_json_input jsonb) RETURNS TABLE(success boolean, message text, attachment_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_attachment_id INT;
    v_file_url VARCHAR(255);
    v_file_name VARCHAR(255);
    v_file_type VARCHAR(50);
    v_file_size BIGINT;
    v_type VARCHAR(50);
    v_note TEXT;
BEGIN
    -- Giải nén JSON input thành các biến
    SELECT
        p_json_input->>'file_url',
        p_json_input->>'file_name',
        p_json_input->>'file_type',
        (p_json_input->>'file_size')::BIGINT,
        p_json_input->>'type',
        p_json_input->>'note'
    INTO
        v_file_url,
        v_file_name,
        v_file_type,
        v_file_size,
        v_type,
        v_note;
 
    -- Kiểm tra đầu vào và ném exception nếu có lỗi
    IF v_file_url IS NULL OR v_file_url = '' THEN
        RAISE EXCEPTION 'File URL không được để trống';
    END IF;
 
    IF v_file_name IS NULL OR v_file_name = '' THEN
        RAISE EXCEPTION 'Tên file không được để trống';
    END IF;
 
    IF v_file_size < 0 THEN
        RAISE EXCEPTION 'Dung lượng file không được âm';
    END IF;
 
    IF p_target_table IS NULL OR p_target_table = '' THEN
        RAISE EXCEPTION 'Tên bảng không được để trống';
    END IF;
 
    IF array_length(p_target_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'Mảng ID không được để trống';
    END IF;
 
    -- Thêm metadata vào bảng attachments
    INSERT INTO attachments (
        file_url, file_name, file_type, file_size, created_at
    ) VALUES (
        v_file_url, v_file_name, v_file_type, v_file_size, NOW()
    )
    RETURNING id INTO v_attachment_id;
 
    -- Thêm các liên kết vào bảng attachment_link mà không sử dụng vòng lặp
    INSERT INTO attachment_link (
        attachment_id, target_table, target_id, type, note, created_at
    )
    SELECT v_attachment_id, p_target_table, unnest(p_target_ids), v_type, v_note, NOW();
    
    -- Trả về kết quả thành công
    RETURN QUERY SELECT TRUE, 'Thêm file đính kèm thành công', v_attachment_id;
EXCEPTION
    WHEN OTHERS THEN
        -- Bắt lỗi và trả về thông báo lỗi
        RETURN QUERY SELECT FALSE, SQLERRM, NULL;
     
END;
$$;


ALTER FUNCTION public.attachment_os_add(p_target_table character varying, p_target_ids integer[], p_json_input jsonb) OWNER TO postgres;

--
-- Name: attachment_os_update(character varying, integer[], jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.attachment_os_update(p_target_table character varying, p_target_ids integer[], p_json_input jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_file_url   VARCHAR(255);
    v_file_name  VARCHAR(255);
    v_file_type  VARCHAR(50);
    v_file_size  BIGINT;
    v_type       VARCHAR(50);
    v_note       TEXT;
    v_attachment_ids INT[];
BEGIN
    -- Giải nén JSON input thành các biến
    SELECT 
        p_json_input->>'file_url',
        p_json_input->>'file_name',
        p_json_input->>'file_type',
        (p_json_input->>'file_size')::BIGINT,
        p_json_input->>'type',
        p_json_input->>'note'
    INTO 
        v_file_url,
        v_file_name,
        v_file_type,
        v_file_size,
        v_type,
        v_note;

    -- Kiểm tra đầu vào hợp lệ
    IF v_file_url IS NULL OR v_file_url = '' THEN
        RAISE EXCEPTION 'File URL không được để trống';
    END IF;
    IF v_file_name IS NULL OR v_file_name = '' THEN
        RAISE EXCEPTION 'Tên file không được để trống';
    END IF;
    IF v_file_size < 0 THEN
        RAISE EXCEPTION 'Dung lượng file không được âm';
    END IF;
    IF p_target_table IS NULL OR p_target_table = '' THEN
        RAISE EXCEPTION 'Tên bảng không được để trống';
    END IF;
    IF array_length(p_target_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'Mảng ID không được để trống';
    END IF;

    -- Lấy danh sách attachment_id cần cập nhật từ attachment_link
    SELECT array_agg(attachment_id)
    INTO v_attachment_ids
    FROM attachment_link
    WHERE target_table = p_target_table 
      AND target_id = ANY(p_target_ids);

    -- Nếu không có attachment nào được tìm thấy, ném lỗi
    IF v_attachment_ids IS NULL OR array_length(v_attachment_ids, 1) = 0 THEN
        RAISE EXCEPTION 'Không tìm thấy tệp đính kèm để cập nhật';
    END IF;

    -- Cập nhật metadata trong bảng attachments với các attachment_id vừa lấy
    UPDATE attachments
    SET file_url = v_file_url,
        file_name = v_file_name,
        file_type = v_file_type,
        file_size = v_file_size,
        modified_at = NOW()
    WHERE id = ANY(v_attachment_ids);

    -- Cập nhật thông tin liên kết trong bảng attachment_link
    UPDATE attachment_link
    SET type = v_type,
        note = v_note,
        modified_at = NOW()
    WHERE attachment_id = ANY(v_attachment_ids)
      AND target_table = p_target_table
      AND target_id = ANY(p_target_ids);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Lỗi khi cập nhật file đính kèm: %', SQLERRM;
END;
$$;


ALTER FUNCTION public.attachment_os_update(p_target_table character varying, p_target_ids integer[], p_json_input jsonb) OWNER TO postgres;

--
-- Name: audit_diff(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_diff(p_audit_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
declare
  rec record;
  changed_keys text[];
  result jsonb;
begin
  select * into rec
  from audit_log
  where id = p_audit_id;

  if rec.operation = 'UPDATE' then
    select array_agg(key)
    into changed_keys
    from jsonb_object_keys(rec.new_data) as key
    where rec.old_data ->> key is distinct from rec.new_data ->> key;

    result := jsonb_build_object(
      'operation', rec.operation,
      'record_id', rec.record_id,
      'table_name', rec.table_name,
      'changed_at', rec.changed_at,
      'changed_by', rec.changed_by,
      'fields_changed', changed_keys,
      'diffs', (
        select jsonb_object_agg(key, jsonb_build_object(
          'old', rec.old_data -> key,
          'new', rec.new_data -> key
        ))
        from unnest(changed_keys) as key
      )
    );

  elsif rec.operation = 'INSERT' then
    result := jsonb_build_object(
      'operation', rec.operation,
      'record_id', rec.record_id,
      'table_name', rec.table_name,
      'changed_at', rec.changed_at,
      'changed_by', rec.changed_by,
      'new_value', rec.new_data
    );

  elsif rec.operation = 'DELETE' then
    result := jsonb_build_object(
      'operation', rec.operation,
      'record_id', rec.record_id,
      'table_name', rec.table_name,
      'changed_at', rec.changed_at,
      'changed_by', rec.changed_by,
      'old_value', rec.old_data
    );
  end if;

  return result;
end;
$$;


ALTER FUNCTION public.audit_diff(p_audit_id integer) OWNER TO postgres;

--
-- Name: audit_filter(text, uuid, text, text, integer, timestamp with time zone, timestamp with time zone, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_filter(p_table_name text DEFAULT NULL::text, p_changed_by uuid DEFAULT NULL::uuid, p_actor_name text DEFAULT NULL::text, p_operation text DEFAULT NULL::text, p_id integer DEFAULT NULL::integer, p_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT NULL::integer, p_offset integer DEFAULT NULL::integer) RETURNS TABLE(id integer, table_name text, operation text, record_id integer, reason text, changed_at timestamp with time zone, changed_by uuid, actor_name text, actor_role text[], realm_roles text[], session_id text, request_id text, tenant_schema text, client_ip text)
    LANGUAGE plpgsql
    AS $$
declare
  tenant_schema text;
begin
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  perform set_config('search_path', tenant_schema, true);

  return query
  select
    audit_log.id,
    audit_log.table_name,
    audit_log.operation,
    audit_log.record_id,
    audit_log.reason,
    audit_log.changed_at,
    audit_log.changed_by,
    audit_log.actor_name,
    audit_log.actor_role,
    audit_log.realm_roles,
    audit_log.session_id,
    audit_log.request_id,
    audit_log.tenant_schema,
    audit_log.client_ip
  from audit_log
  where (p_table_name is null or audit_log.table_name = p_table_name)
    and (p_changed_by is null or audit_log.changed_by = p_changed_by)
    and (p_actor_name is null or audit_log.actor_name ilike '%' || p_actor_name || '%')
    and (p_operation is null or audit_log.operation = p_operation)
    and (p_id is null or audit_log.id = p_id)
    and (p_from is null or audit_log.changed_at >= p_from)
    and (p_to is null or audit_log.changed_at <= p_to)
  order by audit_log.changed_at desc
  limit coalesce(p_limit, 100)
  offset coalesce(p_offset, 0);
end;
$$;


ALTER FUNCTION public.audit_filter(p_table_name text, p_changed_by uuid, p_actor_name text, p_operation text, p_id integer, p_from timestamp with time zone, p_to timestamp with time zone, p_limit integer, p_offset integer) OWNER TO postgres;

--
-- Name: audit_generic(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_generic() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
  rec_id     INT;
  old_json   JSONB;
  new_json   JSONB;
  the_reason TEXT := NULL;
BEGIN
  IF TG_OP = 'INSERT' THEN
    rec_id     := NEW.id;
    old_json   := NULL;
    new_json   := to_jsonb(NEW);
  ELSIF TG_OP = 'UPDATE' THEN
    rec_id     := NEW.id;
    old_json   := to_jsonb(OLD);
    new_json   := to_jsonb(NEW);
  ELSIF TG_OP = 'DELETE' THEN
    rec_id     := OLD.id;
    old_json   := to_jsonb(OLD);
    new_json   := NULL;
  ELSE
    RETURN NULL;
  END IF;

  -- Gọi log_audit qua search_path
  PERFORM log_audit(
    TG_TABLE_NAME,
    TG_OP,
    rec_id,
    old_json,
    new_json,
    the_reason
  );

  -- Trả về giá trị phù hợp để thực thi tiếp
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;$$;


ALTER FUNCTION public.audit_generic() OWNER TO postgres;

--
-- Name: certificate_add(integer, integer, character varying, character varying, character varying, date, date, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.certificate_add(p_emp_id integer, p_type_id integer, p_cert_no character varying, p_name character varying, p_issued_by character varying, p_date_issue date, p_expired_date date, p_note character varying) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Log bắt đầu
  RAISE NOTICE '🎓 Bắt đầu thêm chứng chỉ cho nhân viên ID %', p_emp_id;

  -- Kiểm tra nhân viên tồn tại
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Nhân viên không tồn tại';
    RETURN;
  END IF;

  -- Gọi validate_certificate_input để kiểm tra đầu vào
  PERFORM validate_certificate_input(
    p_type_id, p_cert_no, p_name, p_issued_by, p_date_issue, p_expired_date
  );

  -- Thêm bản ghi vào bảng certificates
  INSERT INTO certificates (
    emp_id, type_id, cert_no, name, issued_by, date_issue, expired_date, note
  )
  VALUES (
    p_emp_id, p_type_id, p_cert_no, p_name, p_issued_by, p_date_issue, p_expired_date, p_note
  );

  -- Gọi history_employees để ghi log
  PERFORM history_employees(p_emp_id, 'ADD_CERTIFICATE');

  -- Log hoàn tất
  RAISE NOTICE 'Đã thêm chứng chỉ và ghi log cho nhân viên ID %', p_emp_id;

  -- Trả về kết quả thành công
  RETURN QUERY SELECT true, 'Tạo chứng chỉ thành công';
EXCEPTION WHEN OTHERS THEN
  -- Bắt lỗi và trả về thông báo lỗi
  RAISE NOTICE 'Lỗi: %', SQLERRM;
  RETURN QUERY SELECT false, SQLERRM;
END;
$$;


ALTER FUNCTION public.certificate_add(p_emp_id integer, p_type_id integer, p_cert_no character varying, p_name character varying, p_issued_by character varying, p_date_issue date, p_expired_date date, p_note character varying) OWNER TO postgres;

--
-- Name: certificate_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.certificate_delete(p_cert_id integer) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
  v_emp_id INT;
  v_type_id INT;
BEGIN
  -- Lấy schema từ JWT
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra chứng chỉ có tồn tại không và lấy emp_id
  SELECT emp_id, type_id INTO v_emp_id, v_type_id
  FROM certificates
  WHERE id = p_cert_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy chứng chỉ cần xóa';
    RETURN;
  END IF;

  -- Nếu chứng chỉ là chứng chỉ chính trong employees → xóa khỏi employees
  UPDATE employees
  SET en_cert_id = NULL
  WHERE id = v_emp_id AND en_cert_id = v_type_id;

  UPDATE employees
  SET it_cert_id = NULL
  WHERE id = v_emp_id AND it_cert_id = v_type_id;

  -- Xóa chứng chỉ
  DELETE FROM certificates
  WHERE id = p_cert_id;

  -- Gọi history_employees để ghi log
  PERFORM history_employees(v_emp_id, 'DELETE_CERTIFICATE');

  -- Trả về kết quả thành công
  RETURN QUERY SELECT true, 'Đã xóa chứng chỉ';
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT false, SQLERRM;
END;
$$;


ALTER FUNCTION public.certificate_delete(p_cert_id integer) OWNER TO postgres;

--
-- Name: certificate_update(integer, integer, character varying, character varying, character varying, date, date, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.certificate_update(p_cert_id integer, p_type_id integer, p_cert_no character varying, p_name character varying, p_issued_by character varying, p_date_issue date, p_expired_date date, p_note character varying) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
  v_emp_id INT;
BEGIN
  -- 1. Lấy schema từ JWT
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;

  -- 2. Set search_path để thao tác đúng schema
  PERFORM set_config('search_path', tenant_schema, true);

  -- 3. Kiểm tra chứng chỉ có tồn tại không
  IF NOT EXISTS (SELECT 1 FROM certificates WHERE id = p_cert_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy chứng chỉ cần cập nhật';
    RETURN;
  END IF;

  -- 4. Gọi validate để kiểm tra logic ngày và dữ liệu
  PERFORM validate_certificate_input(
    p_type_id, p_cert_no, p_name, p_issued_by, p_date_issue, p_expired_date
  );

  -- Lấy id employee
  SELECT emp_id INTO v_emp_id
  FROM certificates WHERE id = p_cert_id;

  -- 5. Cập nhật chứng chỉ
  UPDATE certificates
  SET
    type_id = p_type_id,
    cert_no = p_cert_no,
    name = p_name,
    issued_by = p_issued_by,
    date_issue = p_date_issue,
    expired_date = p_expired_date,
    note = p_note
  WHERE id = p_cert_id;

  -- Gọi history_employees để ghi log
  PERFORM history_employees(v_emp_id, 'UPDATE_CERTIFICATE');

  -- 6. Trả kết quả thành công
  RETURN QUERY SELECT true, 'Cập nhật chứng chỉ thành công';
EXCEPTION WHEN OTHERS THEN
  -- Xử lý lỗi chung
  RAISE NOTICE 'Lỗi: %', SQLERRM;
  RETURN QUERY SELECT false, SQLERRM;
END;
$$;


ALTER FUNCTION public.certificate_update(p_cert_id integer, p_type_id integer, p_cert_no character varying, p_name character varying, p_issued_by character varying, p_date_issue date, p_expired_date date, p_note character varying) OWNER TO postgres;

--
-- Name: check_exists(text, text, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_exists(p_table_name text, p_column_name text, p_value anyelement) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_exists BOOLEAN;
BEGIN
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1)', p_table_name, p_column_name)
    INTO v_exists
    USING p_value;
    RETURN v_exists;
END;
$_$;


ALTER FUNCTION public.check_exists(p_table_name text, p_column_name text, p_value anyelement) OWNER TO postgres;

--
-- Name: check_unique(text, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_unique(p_table_name text, p_column_name text, p_value text, p_exclude_id integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$DECLARE
    v_sql TEXT;
    v_count INTEGER;
BEGIN

    IF p_exclude_id IS NULL THEN
        v_sql := format('SELECT COUNT(*) FROM %I WHERE %I = $1', p_table_name, p_column_name);
        EXECUTE v_sql INTO v_count USING p_value;
    ELSE
        v_sql := format('SELECT COUNT(*) FROM %I WHERE %I = $1 AND id != $2', p_table_name, p_column_name);
        EXECUTE v_sql INTO v_count USING p_value, p_exclude_id;
    END IF;

    RETURN v_count = 0;
END;$_$;


ALTER FUNCTION public.check_unique(p_table_name text, p_column_name text, p_value text, p_exclude_id integer) OWNER TO postgres;

--
-- Name: check_user_permission(uuid, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_user_permission(p_user_id uuid, p_feature_code text, p_action_code text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  PERFORM set_config('search_path', tenant_schema, true);
  RETURN EXISTS (
    SELECT 1
    FROM user_role ur
    JOIN role_permission rp ON ur.role_id = rp.role_id
    JOIN features f ON rp.feature_id = f.id
    JOIN actions a ON rp.action_id = a.id
    WHERE ur.user_id = p_user_id
      AND f.code = p_feature_code
      AND a.code = p_action_code
  );
END;
$$;


ALTER FUNCTION public.check_user_permission(p_user_id uuid, p_feature_code text, p_action_code text) OWNER TO postgres;

--
-- Name: clone_schema_all(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clone_schema_all(source_schema text, target_schema text) RETURNS TABLE(status text, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    obj RECORD;
    func_def TEXT;
    view_def TEXT;
    ddl TEXT;
    table_count INT := 0;
    view_count INT := 0;
    function_count INT := 0;
BEGIN
    -- Tạo schema nếu chưa có
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I;', target_schema);

    -- XÓA FUNCTION
    FOR obj IN
        SELECT p.oid, p.proname, pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = target_schema
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE;', target_schema, obj.proname, obj.args);
        status := 'DROP FUNCTION';
        message := obj.proname || '(' || obj.args || ')';
        RETURN NEXT;
    END LOOP;

    -- XÓA VIEW
    FOR obj IN
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = target_schema
    LOOP
        EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE;', target_schema, obj.table_name);
        status := 'DROP VIEW';
        message := obj.table_name;
        RETURN NEXT;
    END LOOP;

    -- XÓA TABLE
    FOR obj IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = target_schema
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE;', target_schema, obj.tablename);
        status := 'DROP TABLE';
        message := obj.tablename;
        RETURN NEXT;
    END LOOP;

    -- TẠO BẢNG (bao gồm constraints, index, default, identity)
    FOR obj IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = source_schema
    LOOP
        EXECUTE format(
            'CREATE TABLE %I.%I (LIKE %I.%I INCLUDING ALL);',
            target_schema, obj.tablename,
            source_schema, obj.tablename
        );
        table_count := table_count + 1;
        status := 'CREATE TABLE';
        message := obj.tablename;
        RETURN NEXT;
    END LOOP;

    -- TẠO LẠI FOREIGN KEY TỪ SCHEMA NGUỒN
    FOR obj IN
        SELECT conrelid::regclass::text AS table_name,
               conname,
               pg_get_constraintdef(c.oid) AS constraint_def
        FROM pg_constraint c
        JOIN pg_namespace n ON c.connamespace = n.oid
        WHERE contype = 'f'
          AND n.nspname = source_schema
    LOOP
        ddl := format(
            'ALTER TABLE %I.%I ADD CONSTRAINT %I %s;',
            target_schema,
            split_part(obj.table_name, '.', 2),
            obj.conname,
            replace(obj.constraint_def, source_schema || '.', target_schema || '.')
        );
        EXECUTE ddl;
        status := 'CREATE FOREIGN KEY';
        message := obj.conname;
        RETURN NEXT;
    END LOOP;

    -- TẠO FUNCTION
    FOR obj IN
        SELECT p.oid, p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = source_schema
    LOOP
        func_def := pg_get_functiondef(obj.oid);
        func_def := replace(func_def, format('FUNCTION %I.', source_schema), format('FUNCTION %I.', target_schema));
        EXECUTE func_def;
        function_count := function_count + 1;
        status := 'CREATE FUNCTION';
        message := obj.proname;
        RETURN NEXT;
    END LOOP;

    -- TẠO VIEW
    FOR obj IN
        SELECT viewname
        FROM pg_views
        WHERE schemaname = source_schema
    LOOP
        SELECT pg_get_viewdef(format('%I.%I', source_schema, obj.viewname)::regclass, true)
        INTO view_def;

        view_def := replace(view_def, format('%I.', source_schema), format('%I.', target_schema));
        view_def := format('CREATE OR REPLACE VIEW %I.%I AS %s', target_schema, obj.viewname, view_def);

        EXECUTE view_def;
        view_count := view_count + 1;
        status := 'CREATE VIEW';
        message := obj.viewname;
        RETURN NEXT;
    END LOOP;

    -- SAO CHÉP DỮ LIỆU CHO MỘT SỐ BẢNG CỤ THỂ
    FOR obj IN SELECT unnest(ARRAY[
       -- bảng không phụ thuộc
      'provinces', 'districts', 'locations',
      'enum_category', 'enum_lookup',
      -- bảng cha
      'features', 'roles', 'actions',
      -- bảng con
      'feature_action', 'role_permission'
    ]) AS tablename

    LOOP
        EXECUTE format(
            'INSERT INTO %I.%I SELECT * FROM %I.%I;',
            target_schema, obj.tablename,
            source_schema, obj.tablename
        );
        status := 'COPY DATA';
        message := obj.tablename;
        RETURN NEXT;
    END LOOP;

    -- TỔNG KẾT
    status := 'SUMMARY';
    message := format('Đã clone %s table(s), %s view(s), %s function(s)', table_count, view_count, function_count);
    RETURN NEXT;
END;
$$;


ALTER FUNCTION public.clone_schema_all(source_schema text, target_schema text) OWNER TO postgres;

--
-- Name: compare_jsonb_array(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.compare_jsonb_array(p_field_name text, jsonb_old jsonb, jsonb_new jsonb) RETURNS TABLE(field_name text, item_id text, old_value jsonb, new_value jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  WITH old_items AS (
    SELECT elem ->> 'id' AS id, elem AS value
    FROM jsonb_array_elements(jsonb_old) elem
    WHERE elem ? 'id'
  ),
  new_items AS (
    SELECT elem ->> 'id' AS id, elem AS value
    FROM jsonb_array_elements(jsonb_new) elem
    WHERE elem ? 'id'
  )

  -- REMOVED
  SELECT p_field_name, o.id, o.value, NULL
  FROM old_items o
  LEFT JOIN new_items n ON o.id = n.id
  WHERE n.id IS NULL

  UNION ALL

  -- ADDED
  SELECT p_field_name, n.id, NULL, n.value
  FROM new_items n
  LEFT JOIN old_items o ON n.id = o.id
  WHERE o.id IS NULL

  UNION ALL

  -- MODIFIED
  SELECT p_field_name, o.id, o.value, n.value
  FROM old_items o
  JOIN new_items n ON o.id = n.id
  WHERE o.value IS DISTINCT FROM n.value;
END;
$$;


ALTER FUNCTION public.compare_jsonb_array(p_field_name text, jsonb_old jsonb, jsonb_new jsonb) OWNER TO postgres;

--
-- Name: count_employees_by_org(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_employees_by_org(org_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    emp_count INT := 0;  -- Mặc định nếu không có nhân viên
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);
    -- Kiểm tra xem tổ chức có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM organizations WHERE id = org_id) THEN
        RETURN -1;  -- Trả về -1 nếu không tồn tại tổ chức
    END IF;

    -- Đếm số lượng nhân viên của tổ chức nếu tổ chức tồn tại
    SELECT COUNT(*) INTO emp_count 
    FROM employees 
    WHERE organization_id = org_id 
    AND date_resign IS NULL;


    -- Trả về số lượng nhân viên
    RETURN emp_count;

EXCEPTION
    -- Nếu có lỗi khi truy vấn, trả về -1
    WHEN others THEN
        RETURN -1;
END;
$$;


ALTER FUNCTION public.count_employees_by_org(org_id integer) OWNER TO postgres;

--
-- Name: create_report_group(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_report_group(group_name text, module text) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
  insert into report_group (id, group_name, module)
  values (gen_random_uuid(), group_name, module);
exception
  when unique_violation then
    raise exception 'Group name "%" already exists in module "%"', group_name, module;
end;
$$;


ALTER FUNCTION public.create_report_group(group_name text, module text) OWNER TO postgres;

--
-- Name: degree_add(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, date, date, date, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.degree_add(p_emp_id integer, p_type character varying, p_degree_no character varying, p_academic character varying, p_institution character varying, p_classification character varying, p_faculty character varying, p_major character varying, p_education_mode character varying, p_start_date date, p_end_date date, p_graduation_year date, p_training_location character varying, p_note character varying, p_is_main boolean) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  PERFORM set_config('search_path', tenant_schema, true);

  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;

  -- Log bắt đầu
  RAISE NOTICE '🎓 Bắt đầu thêm bằng cấp cho nhân viên ID %', p_emp_id;

  -- Kiểm tra nhân viên tồn tại
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Nhân viên không tồn tại';
    RETURN;
  END IF;

  -- Gọi validate_degree_input để kiểm tra đầu vào
  PERFORM validate_degree_input(
    p_type, p_degree_no, p_academic, p_institution, p_major, 
    p_education_mode, p_start_date, p_end_date, p_graduation_year
  );
  RAISE NOTICE 'Dữ liệu đầu vào hợp lệ';

  -- Nếu là bằng cấp chính, xóa flag các bằng cấp trước đó
  IF p_is_main THEN
    UPDATE degrees
    SET is_main = FALSE
    WHERE emp_id = p_emp_id AND is_main = TRUE;
    RAISE NOTICE 'Đã cập nhật các bằng cấp trước về is_main = FALSE';
  END IF;

  -- Thêm bản ghi vào bảng degrees
  INSERT INTO degrees (
    emp_id, type, degree_no, academic, institution, classification, 
    faculty, major, education_mode, start_date, end_date, 
    graduation_year, training_location, note, is_main
  )
  VALUES (
    p_emp_id, p_type, p_degree_no, p_academic, p_institution, 
    p_classification, p_faculty, p_major, p_education_mode, 
    p_start_date, p_end_date, p_graduation_year, 
    p_training_location, p_note, p_is_main
  );

  -- Nếu là bằng cấp chính thì cập nhật bảng employees
  IF p_is_main THEN
    UPDATE employees
    SET
      degree_type = p_type,
      academic = p_academic,
      institution = p_institution,
      faculty = p_faculty,
      major = p_major,
      graduation_year = p_graduation_year
    WHERE id = p_emp_id;
  END IF;

  -- Gọi history_employees để ghi log
  PERFORM history_employees(p_emp_id, 'ADD_DEGREE');

  -- Log hoàn tất
  RAISE NOTICE 'Đã thêm bằng cấp và ghi log cho nhân viên ID %', p_emp_id;

  -- Trả về kết quả thành công
  RETURN QUERY SELECT true, 'Tạo bằng cấp thành công';
EXCEPTION WHEN OTHERS THEN
  -- Bắt lỗi và trả về thông báo lỗi
  RAISE NOTICE 'Lỗi: %', SQLERRM;
  RETURN QUERY SELECT false, SQLERRM;
END;$$;


ALTER FUNCTION public.degree_add(p_emp_id integer, p_type character varying, p_degree_no character varying, p_academic character varying, p_institution character varying, p_classification character varying, p_faculty character varying, p_major character varying, p_education_mode character varying, p_start_date date, p_end_date date, p_graduation_year date, p_training_location character varying, p_note character varying, p_is_main boolean) OWNER TO postgres;

--
-- Name: degree_delete(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.degree_delete(p_degree_id integer, p_emp_id integer) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_schema TEXT;
    v_is_main BOOLEAN;
BEGIN
    -- 1. Lấy schema từ JWT claims
    v_schema := current_setting('request.jwt.claims', true)::jsonb ->> 'schema';
    IF v_schema IS NULL THEN
        RETURN QUERY SELECT false, 'Không tìm thấy schema trong JWT claims';
        RETURN;
    END IF;
    EXECUTE format('SET search_path TO %I', v_schema);

    -- 2. Kiểm tra bằng cấp và nhân viên có tồn tại
    IF NOT EXISTS (SELECT 1 FROM degrees WHERE id = p_degree_id) THEN
        RETURN QUERY SELECT false, 'Không tìm thấy bằng cấp';
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
        RETURN QUERY SELECT false, 'Không tìm thấy nhân viên';
        RETURN;
    END IF;

    -- 3. Kiểm tra ràng buộc: is_main
    SELECT is_main INTO v_is_main FROM degrees WHERE id = p_degree_id;
    IF v_is_main THEN
        RETURN QUERY SELECT false, 'Không thể xóa bằng cấp chính';
        RETURN;
    END IF;

    -- 4. Xóa bằng cấp
    DELETE FROM degrees WHERE id = p_degree_id;

    -- 5. Ghi log lịch sử nhân viên
    PERFORM history_employees(p_emp_id, 'DELETE_DEGREE');
    
    -- 6. Trả kết quả thành công
    RETURN QUERY SELECT true, 'Xóa bằng cấp thành công';
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
        
END;
$$;


ALTER FUNCTION public.degree_delete(p_degree_id integer, p_emp_id integer) OWNER TO postgres;

--
-- Name: degree_update(integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, date, date, date, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.degree_update(p_degree_id integer, p_emp_id integer, p_type character varying, p_degree_no character varying, p_academic character varying, p_institution character varying, p_classification character varying, p_faculty character varying, p_major character varying, p_education_mode character varying, p_start_date date, p_end_date date, p_graduation_year date, p_training_location character varying, p_note character varying, p_is_main boolean) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
    v_schema TEXT;
BEGIN
    -- Lấy schema từ JWT claims
    v_schema := current_setting('request.jwt.claims', true)::JSON->>'schema';
    IF v_schema IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy schema trong JWT claims';
        RETURN;
    END IF;

    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', v_schema);

    -- Kiểm tra xem bằng cấp và nhân viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM degrees WHERE id = p_degree_id AND emp_id = p_emp_id) THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy bằng cấp hoặc nhân viên';
        RETURN;
    END IF;

    -- Kiểm tra logic ngày tháng
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
        RETURN QUERY SELECT FALSE, 'Ngày bắt đầu không được lớn hơn ngày kết thúc';
        RETURN;
    END IF;

    IF p_end_date IS NOT NULL AND p_graduation_year IS NOT NULL AND p_end_date > p_graduation_year THEN
        RETURN QUERY SELECT FALSE, 'Ngày kết thúc không được lớn hơn năm tốt nghiệp';
        RETURN;
    END IF;

    -- Nếu p_is_main = TRUE, cập nhật các bằng cấp khác của nhân viên thành is_main = FALSE
    IF p_is_main THEN
        UPDATE degrees
        SET is_main = FALSE
        WHERE emp_id = p_emp_id AND is_main = TRUE AND id <> p_degree_id;
    END IF;

    -- Nếu p_is_main = FALSE và hiện tại là bằng chính, cập nhật thông tin nhân viên thành NULL
    IF NOT p_is_main AND EXISTS (SELECT 1 FROM degrees WHERE id = p_degree_id AND is_main = TRUE) THEN
        UPDATE employees
        SET
            degree_type = NULL,
            academic = NULL,
            institution = NULL,
            faculty = NULL,
            major = NULL,
            graduation_year = NULL
        WHERE id = p_emp_id;
    END IF;

    -- Cập nhật thông tin bằng cấp
    UPDATE degrees
    SET
        type = COALESCE(p_type, type),
        degree_no = COALESCE(p_degree_no, degree_no),
        academic = COALESCE(p_academic, academic),
        institution = COALESCE(p_institution, institution),
        classification = COALESCE(p_classification, classification),
        faculty = COALESCE(p_faculty, faculty),
        major = COALESCE(p_major, major),
        education_mode = COALESCE(p_education_mode, education_mode),
        start_date = COALESCE(p_start_date, start_date),
        end_date = COALESCE(p_end_date, end_date),
        graduation_year = COALESCE(p_graduation_year, graduation_year),
        training_location = COALESCE(p_training_location, training_location),
        note = COALESCE(p_note, note),
        is_main = COALESCE(p_is_main, is_main)
    WHERE id = p_degree_id;

    -- Nếu bằng cấp được đánh dấu là chính, cập nhật thông tin nhân viên
    IF p_is_main THEN
        UPDATE employees
        SET
            degree_type = COALESCE(p_type, degree_type),
            academic = COALESCE(p_academic, academic),
            institution = COALESCE(p_institution, institution),
            faculty = COALESCE(p_faculty, faculty),
            major = COALESCE(p_major, major),
            graduation_year = COALESCE(p_graduation_year, graduation_year)
        WHERE id = p_emp_id;
    END IF;

    -- Ghi log lịch sử nhân viên
    PERFORM history_employees(p_emp_id, 'UPDATE_DEGREE');

    -- Trả kết quả thành công
    RETURN QUERY SELECT TRUE, 'Cập nhật bằng cấp thành công và ghi log';
EXCEPTION
    WHEN OTHERS THEN
        -- Trả kết quả lỗi
        RETURN QUERY SELECT FALSE, 'Lỗi: ' || SQLERRM;
END;$$;


ALTER FUNCTION public.degree_update(p_degree_id integer, p_emp_id integer, p_type character varying, p_degree_no character varying, p_academic character varying, p_institution character varying, p_classification character varying, p_faculty character varying, p_major character varying, p_education_mode character varying, p_start_date date, p_end_date date, p_graduation_year date, p_training_location character varying, p_note character varying, p_is_main boolean) OWNER TO postgres;

--
-- Name: delete_job_titles(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_job_titles(p_job_titles_id integer) RETURNS TABLE(status text, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
    employee_count INT;
    job_title_exists BOOLEAN;
    job_title_name TEXT;
    stt_err TEXT := 'ERROR';
    stt_suc TEXT := 'SUCCESS';
    sttt_warning TEXT := 'WARNING';
    tenant_schema TEXT;
BEGIN
    BEGIN
        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    
        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- 🔹 1️ Kiểm tra NULL
        IF p_job_titles_id IS NULL THEN
            RETURN QUERY 
            SELECT stt_err, 'Lỗi: ID chức danh không được để trống.';
            RETURN;
        END IF;

        -- 🔹 2️ Kiểm tra chức danh có tồn tại không và lấy tên
        SELECT name INTO job_title_name
        FROM job_titles 
        WHERE id = p_job_titles_id 
            AND is_active is TRUE;

        -- Nếu không tìm thấy, trả về lỗi
        IF job_title_name IS NULL THEN
            RETURN QUERY 
            SELECT stt_err, 'Lỗi: Chức danh không tồn tại hoặc đã bị xóa.';
            RETURN;
        END IF;

        -- 🔹 3️ Kiểm tra số lượng nhân viên đang giữ chứng danh này
        SELECT COUNT(*) INTO employee_count
        FROM employees 
        WHERE job_title_id = p_job_titles_id 
        AND date_resign IS NULL; -- Chỉ tính nhân viên chưa nghỉ việc

        -- Nếu vẫn còn nhân viên, trả về thông báo lỗi
        IF employee_count > 0 THEN
            RETURN QUERY 
            SELECT sttt_warning, 'Lỗi: Không thể xóa chức danh do còn ' || employee_count || ' nhân viên đang giữ chức vụ, vui lòng gán lại chức danh.';
            RETURN;
        END IF;

        -- Nếu vẫn còn vị trí công việc đang hoạt động, trả lỗi
        IF EXISTS (
            SELECT 1 FROM job_title_organizations
            WHERE job_title_id = p_job_titles_id
                AND is_active = TRUE
        ) THEN
            RETURN QUERY 
            SELECT sttt_warning, 'Lỗi: Không thể xóa chức danh do còn vị trí công việc đang hoạt động.';
            RETURN;
        END IF;


    -- 🔹 4️ Nếu không còn nhân viên, thực hiện cập nhật trạng thái
        UPDATE job_titles 
        SET is_active = FALSE 
        WHERE id = p_job_titles_id;

        RETURN QUERY 
        SELECT stt_suc, 'Chức danh ' || job_title_name || ' đã được xóa thành công.';

    EXCEPTION
        WHEN OTHERS THEN
            -- Bắt lỗi nếu có vấn đề xảy ra trong quá trình cập nhật
            RETURN QUERY 
            SELECT stt_err, 'Lỗi: khi xóa chức danh: ' || SQLERRM;
    END;

END;$$;


ALTER FUNCTION public.delete_job_titles(p_job_titles_id integer) OWNER TO postgres;

--
-- Name: delete_jobtile_org(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_jobtile_org(p_job_title_org_id integer) RETURNS TABLE(status text, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_job_title_id INT;
    v_org_id INT;
    v_emp_count INT;
    tenant_schema TEXT;
    v_is_active BOOLEAN;
BEGIN 
    BEGIN
        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
        PERFORM set_config('search_path', tenant_schema, true);     

        -- Lấy thông tin job_title_id và organization_id
        SELECT job_title_id, org_id, is_active
        INTO v_job_title_id, v_org_id, v_is_active
        FROM job_title_organizations
        WHERE id = p_job_title_org_id
        FOR UPDATE;

        -- Nếu không có bản ghi nào
        IF NOT FOUND THEN
            RETURN QUERY SELECT 'false', 'Vị trí công việc không tồn tại';
            RETURN;
        END IF;


        -- Nếu đã ngưng hoạt động
        IF NOT v_is_active THEN
            RETURN QUERY SELECT 'false', 'Vị trí công việc đã ngưng hoạt động';
            RETURN;
        END IF;

        -- Kiểm tra xem có nhân viên nào đang dùng vị trí đó không
        SELECT COUNT(*) INTO v_emp_count
        FROM employee_list_view elv
        WHERE elv.job_title_id = v_job_title_id
          AND elv.organization_id = v_org_id
          AND elv.status IN ('trial', 'waiting', 'active');

        IF v_emp_count > 0 THEN
            RETURN QUERY SELECT 'false', 'Vị trí công việc đang có nhân viên làm việc. Chuyển công việc của họ trước khi xóa';
            RETURN;
        END IF;

        -- Cập nhật is_active
        UPDATE job_title_organizations
        SET is_active = false
        WHERE id = p_job_title_org_id;

        RETURN QUERY SELECT 'true', 'Xóa vị trí công việc thành công';

    EXCEPTION 
        WHEN OTHERS THEN
            RETURN QUERY SELECT 'false', 'Lỗi: ' || SQLERRM;
            RETURN;
    END;
END;$$;


ALTER FUNCTION public.delete_jobtile_org(p_job_title_org_id integer) OWNER TO postgres;

--
-- Name: dissolve_organization(integer, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dissolve_organization(p_org_id integer, p_dissolve_date date, p_reason text) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_employee_count INT;
    v_assignment_count INT;
    v_child_org_count INT;
    v_org RECORD;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);
    
    -- Kiểm tra nếu đơn vị tồn tại
    SELECT * INTO v_org FROM organizations WHERE id = p_org_id;
    IF NOT FOUND THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Tổ chức không tồn tại', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra nếu đơn vị đang hoạt động
    IF v_org.is_active = FALSE THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị không còn hoạt động', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra xem đơn vị có nhân sự chính thức, thử việc, hoặc chờ onboard hay không
    SELECT COUNT(*) INTO v_employee_count
    FROM employee_list_view
    WHERE organization_id = p_org_id
      AND status IN ('trial', 'waiting', 'active');

    IF v_employee_count > 0 THEN
      RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị còn nhân viên đang làm việc, thử việc hoặc chờ nhận việc', 'org_id', p_org_id);
    END IF;


    -- Kiểm tra xem đơn vị có nhân sự đang kiêm nhiệm hay không
    SELECT COUNT(*) INTO v_assignment_count FROM job_assignments WHERE org_id = p_org_id AND is_active = TRUE;
    IF v_assignment_count > 0 THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị còn nhân viên kiêm nhiệm', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra xem đơn vị có đơn vị con còn hoạt động hay không
    SELECT COUNT(*) INTO v_child_org_count 
    FROM organizations 
    WHERE parent_org_id = p_org_id AND is_active = TRUE;

    IF v_child_org_count > 0 THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị còn đơn vị con đang hoạt động', 'org_id', p_org_id);
    END IF;

    -- Cập nhật trạng thái của đơn vị
    UPDATE organizations
    SET is_active = FALSE, expired_date = p_dissolve_date, version = version + 1
    WHERE id = p_org_id
    RETURNING * INTO v_org;

    -- Ghi log vào org_log
    INSERT INTO org_log (
        org_id, action, reason, log_date, code, name, en_name, category_id, parent_org_id, 
        location_id, phone, email, effective_date, expired_date, cost_centers_id, 
        is_active, approve_struct, decision_no, decision_date, description, general_manager_id, direct_manager_id, version
    ) 
    VALUES (
        v_org.id, 'DISSOLVE', p_reason, NOW(), v_org.code, v_org.name, v_org.en_name, v_org.category_id, v_org.parent_org_id, 
        v_org.location_id, v_org.phone, v_org.email, v_org.effective_date, p_dissolve_date, v_org.cost_centers_id, 
        FALSE, v_org.approve_struct, v_org.decision_no, v_org.decision_date, v_org.description, 
        v_org.general_manager_id, v_org.direct_manager_id, v_org.version
    );

    -- Trả về kết quả thành công
    RETURN json_build_object('status', 'SUCCESS', 'message', 'Giải thể tổ chức thành công', 'org_id', v_org.id);

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Lỗi khi giải thể: ' || SQLERRM, 'org_id', p_org_id);
END;
$$;


ALTER FUNCTION public.dissolve_organization(p_org_id integer, p_dissolve_date date, p_reason text) OWNER TO postgres;

--
-- Name: employee_add(character varying, character varying, integer, character varying, date, integer, integer, date, date, integer, integer, public.marital_statuses, character varying, integer, character varying, integer, integer, integer, character varying, character varying, character varying, public.gender, public.education_level, integer, character varying, character varying, date, date, date, character varying, public.employee_types, character varying, integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_add(p_last_name character varying, p_first_name character varying, p_nationality_id integer, p_identity_no character varying, p_date_issue date, p_place_issue_id integer, p_job_title_id integer, p_date_join date, p_dob date, p_ethnicity_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_organization_id integer, p_work_location_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_gender public.gender, p_education_level public.education_level, p_change_type_id integer, p_decision_no character varying DEFAULT NULL::character varying, p_decision_signer character varying DEFAULT NULL::character varying, p_decision_sign_date date DEFAULT NULL::date, p_start_date_change date DEFAULT NULL::date, p_end_date_change date DEFAULT NULL::date, p_middle_name character varying DEFAULT NULL::character varying, p_employee_type public.employee_types DEFAULT '1'::public.employee_types, p_secondary_phone character varying DEFAULT NULL::character varying, p_manager_id integer DEFAULT NULL::integer, p_date_identity_expiry date DEFAULT NULL::date) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$DECLARE
    v_error_details JSONB := '[]'::JSONB;
    v_validation_result JSONB;
    v_employee_id INTEGER;
    v_full_name TEXT;
    v_emp_code TEXT;
    v_job_change_type VARCHAR;
    tenant_schema TEXT;
BEGIN
    -- Get schema from JWT and set search path
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);
  
 
    -- Generate full name once
    v_full_name := CONCAT(p_last_name, ' ', COALESCE(p_middle_name, ''), ' ', p_first_name);
 
    -- Validate input data
    v_validation_result := validate_employee_add(
        p_last_name,
        p_middle_name,
        p_first_name,
        p_nationality_id,
        p_identity_no,
        p_date_issue,
        p_date_identity_expiry,
        p_place_issue_id,
        p_job_title_id,
        p_date_join,
        p_start_date_change,
        p_end_date_change,
        p_change_type_id,
        p_dob,
        p_ethnicity_id,
        p_religion_id,
        p_marital_status,
        p_permanent_address,
        p_permanent_district_id,
        p_temporary_address,
        p_temporary_district_id,
        p_organization_id,
        p_work_location_id,
        p_email_internal,
        p_email_external,
        p_phone,
        p_secondary_phone,
        p_gender,
        p_education_level,
        p_employee_type,
        p_manager_id
    );
 
    IF (v_validation_result->>'status')::BOOLEAN = false THEN
        RETURN v_validation_result;
    END IF;
 
    v_emp_code := generate_new_emp_code();

    SELECT value INTO v_job_change_type
    FROM enum_lookup WHERE id = p_change_type_id;

    -- Begin transaction
    BEGIN
        -- Insert new employee
        INSERT INTO employees (
            emp_code,
            last_name,
            middle_name,
            first_name,
            full_name,
            nationality_id,
            identity_no,
            date_issue,
            date_identity_expiry,
            place_issue_id,
            job_title_id,
            date_join,
            decision_no,
            decision_signer,
            decision_sign_date,
            start_date_change, 
            end_date_change,
            job_change_type,
            dob,
            ethnicity_id,
            religion_id,
            marital_status,
            permanent_address,
            permanent_district_id,
            temporary_address,
            temporary_district_id,
            organization_id,
            work_location_id,
            email_internal,
            email_external,
            phone,
            secondary_phone,
            gender,
            education_level,
            employee_type,
            manager_id
        ) VALUES (
            v_emp_code,
            p_last_name,
            p_middle_name,
            p_first_name,
            v_full_name,
            p_nationality_id,
            p_identity_no,
            p_date_issue,
            p_date_identity_expiry,
            p_place_issue_id,
            p_job_title_id,
            p_date_join,
            p_decision_no,
            p_decision_signer,
            p_decision_sign_date,
            p_start_date_change, 
            p_end_date_change,
            v_job_change_type,
            p_dob,
            p_ethnicity_id,
            p_religion_id,
            p_marital_status,
            p_permanent_address,
            p_permanent_district_id,
            p_temporary_address,
            p_temporary_district_id,
            p_organization_id,
            p_work_location_id,
            p_email_internal,
            p_email_external,
            p_phone,
            p_secondary_phone,
            p_gender,
            p_education_level,
            p_employee_type,
            p_manager_id
        ) RETURNING id INTO v_employee_id;
 
        -- Log employee history
        PERFORM history_employees(v_employee_id, 'ADD_EMPLOYEE');
 
        -- Return success response
        RETURN jsonb_build_object(
            'code', 200,
            'status', true,
            'message', 'Thêm mới nhân viên thành công',
            'data', jsonb_build_object(
                'employee_id', v_employee_id,
                'emp_code', v_emp_code,
                'full_name', v_full_name
            )
        );
 
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error details
            v_error_details := jsonb_build_array(
                jsonb_build_object(
                    'error', SQLERRM,
                    'detail', SQLSTATE
                )
            );
            
            RETURN jsonb_build_object(
                'code', 500,
                'status', false,
                'message', 'Lỗi hệ thống: ' || SQLERRM,
                'errors', v_error_details
            );
    END;
END;$$;


ALTER FUNCTION public.employee_add(p_last_name character varying, p_first_name character varying, p_nationality_id integer, p_identity_no character varying, p_date_issue date, p_place_issue_id integer, p_job_title_id integer, p_date_join date, p_dob date, p_ethnicity_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_organization_id integer, p_work_location_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_gender public.gender, p_education_level public.education_level, p_change_type_id integer, p_decision_no character varying, p_decision_signer character varying, p_decision_sign_date date, p_start_date_change date, p_end_date_change date, p_middle_name character varying, p_employee_type public.employee_types, p_secondary_phone character varying, p_manager_id integer, p_date_identity_expiry date) OWNER TO postgres;

--
-- Name: employee_avatar_update(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_avatar_update(emp_id integer, avatar_url text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
    error_details JSONB := '[]'::JSONB;
    tenant_schema TEXT;
    updated_employee JSONB;
BEGIN
    -- Get schema from JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Set search_path according to schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM employees WHERE id = emp_id) THEN
        error_details := error_details || jsonb_build_object(
            'field', 'emp_id',
            'message_error', 'Không tìm thấy nhân viên'
        );
    END IF;

    -- Validate avatar file extension
    IF avatar_url IS NOT NULL AND avatar_url != '' THEN
        IF NOT (avatar_url ~* '\.(jpg|jpeg|png|gif|webp)$') THEN
            error_details := error_details || jsonb_build_object(
                'field', 'avatar_url',
                'message_error', 'Định dạng file không hợp lệ. Các định dạng được phép: jpg, jpeg, png, gif, webp'
            );
        END IF;
    END IF;

    -- Return error if validation fails
    IF jsonb_array_length(COALESCE(error_details, '[]'::JSONB)) > 0 THEN
        RETURN jsonb_build_object(
            'code', 400,
            'status', false,
            'message', 'Xác thực thất bại',
            'errors', error_details
        );
    END IF;

    -- Update employee avatar
    UPDATE employees
    SET avatar = avatar_url
    WHERE id = emp_id
    RETURNING jsonb_build_object(
        'id', id,
        'avatar_url', avatar
    ) INTO updated_employee;

    -- Gọi history_employees để ghi log
    PERFORM history_employees(emp_id, 'UPDATE_AVARTAR');

    -- Return success response
    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Cập nhật ảnh đại diện nhân viên thành công',
        'data', updated_employee
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code', 500,
            'status', false,
            'message', 'Lỗi máy chủ nội bộ',
            'errors', jsonb_build_array(
                jsonb_build_object(
                    'field', 'general',
                    'message_error', SQLERRM
                )
            )
        );
END;
$_$;


ALTER FUNCTION public.employee_avatar_update(emp_id integer, avatar_url text) OWNER TO postgres;

--
-- Name: employee_contacts_get(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_contacts_get(p_id integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    v_result      jsonb;
BEGIN
    -- 1. Lấy schema từ JWT và set search_path
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- 2. Truy vấn với CTE để lấy status từ employee_list_view
    WITH employee_status AS (
        SELECT id, status
        FROM employee_list_view
        WHERE id = p_id
    )
    SELECT jsonb_build_object(
        'code',   200,
        'status', true,
        'message', 'Lấy thông tin nhân viên và quản lý thành công',
        'data', jsonb_build_object(
            'employee_id',        e.id,
            'emp_code',           e.emp_code,
            'employee_name',      e.full_name,
            'status',             es.status,
            'email_internal',     e.email_internal,
            'phone',              e.phone,
            'secondary_phone',    e.secondary_phone,
            'avatar_url',         e.avatar,
            'job_title',          jt.name,
            'job_title_code',     jt.code,
            'organization_id',    org.id,
            'organization_name',  org.name,
            'work_location_id',   loc.id,
            'work_location_name', CASE WHEN loc.id IS NOT NULL
                                      THEN concat(loc.name, ' - ', loc.address)
                                      ELSE NULL END,
            'managers',           COALESCE(
                                    get_org_parent(org.id,
                                        get_organization_level(org.id, tenant_schema)
                                    ), '[]'::jsonb
                                 ),
            'direct_manager',     CASE WHEN org.direct_manager_id IS NOT NULL THEN
                                       jsonb_build_object('id', dm.id, 'name', dm.full_name)
                                   ELSE NULL END,
            'general_manager',    CASE WHEN org.general_manager_id IS NOT NULL THEN
                                       jsonb_build_object('id', gm.id, 'name', gm.full_name)
                                   ELSE NULL END
        )
    ) INTO v_result
    FROM employees e
    JOIN organizations org ON e.organization_id = org.id
    INNER JOIN employee_status es ON e.id = es.id
    LEFT JOIN job_titles jt ON e.job_title_id = jt.id
    LEFT JOIN locations loc ON e.work_location_id = loc.id
    LEFT JOIN employees dm ON org.direct_manager_id = dm.id
    LEFT JOIN employees gm ON org.general_manager_id = gm.id
    WHERE e.id = p_id;

    -- 3. Xử lý trường hợp không tìm thấy
    IF v_result IS NULL THEN
        RETURN jsonb_build_object(
            'code',   404,
            'status', false,
            'message', 'Không tìm thấy nhân viên',
            'errors', jsonb_build_array(
                jsonb_build_object(
                    'field', 'id',
                    'message_error', 'Không tìm thấy nhân viên với ID đã cho'
                )
            )
        );
    END IF;

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code',   500,
            'status', false,
            'message', 'Lỗi máy chủ',
            'errors', jsonb_build_array(
                jsonb_build_object(
                    'field', 'general',
                    'message_error', SQLERRM
                )
            )
        );
END;
$$;


ALTER FUNCTION public.employee_contacts_get(p_id integer) OWNER TO postgres;

--
-- Name: employee_count_org_jobtitle(integer, integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_count_org_jobtitle(p_org_id integer, p_job_title_id integer, p_date date) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
    v_count      INT;
    v_child_orgs INT[];
BEGIN
    -- 1. Retrieve all descendant organizations
    v_child_orgs := organization_get_childs(p_org_id);

    -- 2. Ensure parent org is included, initialize array if needed
    IF v_child_orgs IS NULL THEN
        v_child_orgs := ARRAY[p_org_id];
    ELSE
        v_child_orgs := array_append(v_child_orgs, p_org_id);
    END IF;

    -- 3. Count distinct active employees matching the job title
    SELECT COUNT(DISTINCT e.id)
    INTO v_count
    FROM employees e
    WHERE e.organization_id = ANY(v_child_orgs)
      AND e.job_title_id = p_job_title_id
      AND e.date_join <= p_date
      AND (e.date_resign IS NULL OR e.date_resign > p_date);

    -- 4. Return the count, default to 0 if NULL
    RETURN COALESCE(v_count, 0);
END;$$;


ALTER FUNCTION public.employee_count_org_jobtitle(p_org_id integer, p_job_title_id integer, p_date date) OWNER TO postgres;

--
-- Name: employee_decline_job(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_decline_job(p_employee_id integer, p_reason text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
begin

  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  PERFORM set_config('search_path', tenant_schema, true);

  IF EXISTS (
    SELECT 1 FROM employees e
    WHERE e.id = p_employee_id
      AND e.date_join IS NOT NULL
      AND e.date_probation_start IS NULL
      AND e.date_official_start IS NULL
      AND e.date_resign IS NULL
  ) THEN
    UPDATE employees
    SET date_resign = CURRENT_DATE,
        note = CONCAT(COALESCE(note, ''), ' | Từ chối nhận việc: ', p_reason)
    WHERE id = p_employee_id;

    RETURN QUERY
    SELECT true, 'Đã cập nhật trạng thái từ chối nhận việc.';
  ELSE
    RETURN QUERY
    SELECT false, 'Không đủ điều kiện để từ chối nhận việc.';
  END IF;
END;
$$;


ALTER FUNCTION public.employee_decline_job(p_employee_id integer, p_reason text) OWNER TO postgres;

--
-- Name: employee_get_full_info(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_get_full_info(p_emp_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    result JSONB;
    personal_info_part1 JSONB;
    personal_info_part2 JSONB;
BEGIN
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    PERFORM set_config('search_path', tenant_schema, true);

    SELECT 
        jsonb_build_object(
            'id', e.id,
            'code', e.emp_code,
            'full_name', e.full_name,
            'gender', e.gender,
            'date_of_birth', e.dob,
            'hometown_name', p.name,
            'nationality', n.name,
            'ethnicity', en.name,
            'religion', rl.name,
            'marital_status', e.marital_status,
            'identity_card', e.identity_no,
            'identity_card_date', e.date_issue,
            'identity_card_place', pi.name,
            'identity_expiry_date', e.date_identity_expiry,
            'old_identity_card', e.old_identity_no,
            'old_identity_card_date', e.old_date_issue,
            'email_internal', e.email_internal,
            'email_personal', e.email_external,
            'phone', e.phone,
            'secondary_phone', e.secondary_phone,
            'home_phone', e.home_phone,
            'company_phone', e.company_phone,
            'permanent_address', e.permanent_address,
            'permanent_province', pr.name,
            'permanent_district', d.name,
            'temporary_address', e.temporary_address,
            'temporary_province', tpr.name,
            'temporary_district', td.name
        )
    INTO personal_info_part1
    FROM employees e
    LEFT JOIN enum_lookup rl ON rl.id = e.religion_id
    LEFT JOIN enum_lookup en ON en.id = e.ethnicity_id
    LEFT JOIN enum_lookup pi ON pi.id = e.place_issue_id
    LEFT JOIN enum_lookup n ON n.id = e.nationality_id
    LEFT JOIN provinces pr ON pr.id = e.permanent_district_id
    LEFT JOIN districts d ON d.id = e.permanent_district_id
    LEFT JOIN provinces tpr ON tpr.id = e.temporary_district_id
    LEFT JOIN districts td ON td.id = e.temporary_district_id
    LEFT JOIN provinces p ON p.id = e.hometown_provinces_id
    WHERE e.id = p_emp_id;

    SELECT 
        jsonb_build_object(
            'education_level', e.education_level,
            'academic', e.academic,
            'school', e.institution,
            'major', e.major,
            'date_join', e.date_join,
            'real_date_join', e.date_official_start,
            'organization_name', og.name,
            'job_title_id', e.job_title_id,
            'job_title_name', jt.name,
            'recruitment_source', e.profile_introduced,
            'decision_no', e.decision_no,
            'decision_signer', e.decision_signer,
            'decision_sign_date', e.decision_sign_date,
            'manager_name', mgr.full_name,
            'manager_id', mgr.id,
            'manager_code', mgr.emp_code,
            'job_change_type_name', e.job_change_type,
            'start_date_change', e.start_date_change,
            'end_date_change', e.end_date_change,
            'work_location_name', wl.name,
            'work_location_address', wl.address,
            'bank_account', e.bank_account_no,
            'bank_name', e.bank_name,
            'cif_code', e.cif_code,
            'tax_code', e.tax_no,
            'social_insurance', e.is_social_insurance,
            'status', 'active',
            'occupation', occ.name,
            'avatar_url', e.avatar,
            'date_resign', e.date_resign,
            'other_info', jsonb_build_object(
                'union_join_date', e.union_start_date,
                'union_fee_date', e.union_fee_date,
                'union_decision_number', e.union_decision_no,
                'union_position', e.union_position,
                'union_description', e.work_note,
                'appointment_decision_number', e.decision_no,
                'appointment_decision_date', e.decision_sign_date,
                'party_join_day', e.party_start_date,
                'party_official_date', e.party_official_date,
                'union_join_day', e.union_youth_start_date,
                'union_organization_name', e.union_organization_name,
                'union_status', e.union_status
            )
        )
    INTO personal_info_part2
    FROM employees e
    LEFT JOIN job_titles jt ON jt.id = e.job_title_id
    LEFT JOIN organizations og ON og.id = e.organization_id
    LEFT JOIN employees mgr ON mgr.id = e.manager_id
    LEFT JOIN locations wl ON wl.id = e.work_location_id
    LEFT JOIN enum_lookup occ ON occ.id = e.occupation_id
    WHERE e.id = p_emp_id;

    result := jsonb_build_object(
        'personal_information', personal_info_part1 || personal_info_part2,
        'family', (
            SELECT jsonb_agg(to_jsonb(fd) - 'emp_id') FROM family_dependents fd WHERE fd.emp_id = p_emp_id
        ),
        'work_history', (
            SELECT jsonb_agg(to_jsonb(wk) - 'emp_id') FROM work_histories wk WHERE wk.emp_id = p_emp_id
        ),
        'education', (
            SELECT jsonb_agg(to_jsonb(d) - 'emp_id') FROM degrees d WHERE d.emp_id = p_emp_id
        ),
        'certificates', (
            SELECT jsonb_agg(to_jsonb(c) - 'emp_id') FROM certificates c WHERE c.emp_id = p_emp_id
        ),
        'reward', (
            SELECT jsonb_agg(to_jsonb(r) - 'emp_id') FROM reward_disciplinary r WHERE r.emp_id = p_emp_id AND r.type = 'REWARD'
        ),
        'disciplines', (
            SELECT jsonb_agg(to_jsonb(r) - 'emp_id') FROM reward_disciplinary r WHERE r.emp_id = p_emp_id AND r.type = 'DISCIPLINARY'
        ),
        'experiences', (
            SELECT jsonb_agg(to_jsonb(ex) - 'emp_id') FROM external_experiences ex WHERE ex.emp_id = p_emp_id
        )
    );

    RETURN result;
END;
$$;


ALTER FUNCTION public.employee_get_full_info(p_emp_id integer) OWNER TO postgres;

--
-- Name: employee_inf_personal_update(integer, character varying, character varying, character varying, public.gender, date, integer, integer, integer, integer, public.marital_statuses, integer, character varying, date, date, integer, character varying, date, integer, public.education_level, character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_inf_personal_update(p_id integer, p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_gender public.gender, p_dob date, p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no character varying, p_old_date_issue date, p_old_place_issue_id integer, p_education_level public.education_level, p_degree_type character varying, p_institution character varying, p_major character varying, p_en_cert_id integer, p_it_cert_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_home_phone character varying, p_company_phone character varying, p_cif_code integer, p_bank_account_no character varying, p_bank_name character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_error_details JSONB := '[]'::JSONB;
    v_tenant_schema TEXT;
    v_full_name VARCHAR(100);
    v_validation_result JSONB;
BEGIN
    -- Get tenant schema from JWT
    v_tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', v_tenant_schema);

    -- Validate input data
    SELECT validate_employee_inf_personal(
        p_id,
        p_last_name,
        p_middle_name,
        p_first_name,
        p_gender,
        p_dob,
        p_hometown_provinces_id,
        p_ethnicity_id,
        p_nationality_id,
        p_religion_id,
        p_marital_status,
        p_occupation_id,
        p_identity_no,
        p_date_issue,
        p_date_identity_expiry,
        p_place_issue_id,
        p_old_identity_no,
        p_old_date_issue,
        p_old_place_issue_id,
        p_education_level,
        p_degree_type,
        p_institution,
        p_major,
        p_en_cert_id,
        p_it_cert_id,
        p_email_internal,
        p_email_external,
        p_phone,
        p_secondary_phone,
        p_home_phone,
        p_company_phone,
        p_cif_code,
        p_bank_account_no,
        p_bank_name
    ) INTO v_validation_result;

    -- Check validation result
    IF NOT (v_validation_result->>'status')::BOOLEAN THEN
        RETURN v_validation_result;
    END IF;

    -- Construct full name
    v_full_name := CONCAT(p_last_name, ' ', p_middle_name, ' ', p_first_name);

    -- Update employee information
    UPDATE employees
    SET
        last_name = p_last_name,
        middle_name = p_middle_name,
        first_name = p_first_name,
        full_name = v_full_name,
        gender = p_gender,
        dob = p_dob,
        hometown_provinces_id = p_hometown_provinces_id,
        ethnicity_id = p_ethnicity_id,
        nationality_id = p_nationality_id,
        religion_id = p_religion_id,
        marital_status = p_marital_status,
        occupation_id = p_occupation_id,
        identity_no = p_identity_no,
        date_issue = p_date_issue,
        date_identity_expiry = p_date_identity_expiry,
        place_issue_id = p_place_issue_id,
        old_identity_no = p_old_identity_no,
        old_date_issue = p_old_date_issue,
        old_place_issue_id = p_old_place_issue_id,
        education_level = p_education_level,
        degree_type = p_degree_type,
        institution = p_institution,
        major = p_major,
        en_cert_id = p_en_cert_id,
        it_cert_id = p_it_cert_id,
        email_internal = p_email_internal,
        email_external = p_email_external,
        phone = p_phone,
        secondary_phone = p_secondary_phone,
        home_phone = p_home_phone,
        company_phone = p_company_phone,
        cif_code = p_cif_code,
        bank_account_no = p_bank_account_no,
        bank_name = p_bank_name
    WHERE id = p_id;

    -- Gọi history_employees để ghi log
    PERFORM history_employees(p_id, 'UPDATE_EMPLOYEE');

    -- Return success response
    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Cập nhật thông tin cá nhân thành công'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code', 500,
            'status', false,
            'message', 'Lỗi hệ thống: ' || SQLERRM
        );
END;
$$;


ALTER FUNCTION public.employee_inf_personal_update(p_id integer, p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_gender public.gender, p_dob date, p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no character varying, p_old_date_issue date, p_old_place_issue_id integer, p_education_level public.education_level, p_degree_type character varying, p_institution character varying, p_major character varying, p_en_cert_id integer, p_it_cert_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_home_phone character varying, p_company_phone character varying, p_cif_code integer, p_bank_account_no character varying, p_bank_name character varying) OWNER TO postgres;

--
-- Name: employee_job_title_update(integer, integer, integer[], text, character varying, date, date, date, integer, character varying, integer, public.employee_types, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_job_title_update(p_new_job_title_id integer, p_new_organization_id integer, p_employee_ids integer[], p_decision_signer text, p_decision_no character varying, p_decision_sign_date date, p_end_date_change_old date, p_start_date_change date, p_job_change_type_id integer, p_work_note character varying, p_manager_id integer, p_employee_type public.employee_types DEFAULT '3'::public.employee_types, p_reason text DEFAULT NULL::text) RETURNS TABLE(status text, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
    stt_err TEXT := 'ERROR';
    stt_suc TEXT := 'SUCCESS';
    affected_rows INT;
    tenant_schema TEXT;
    v_work_status BOOLEAN;
    v_work_message TEXT;
    v_job_change_type TEXT;
    v_employee_id INT;
    v_location_id INT;
    v_updated_count INT := 0;
BEGIN

     -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);
    
    -- Kiểm tra đầu vào
    IF p_new_job_title_id IS NULL OR p_new_job_title_id <= 0 THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: ID chức danh mới không hợp lệ.';
        RETURN;
    END IF;

    -- Kiểm tra đơn vị có tồn tại không
    IF p_new_organization_id IS NULL OR p_new_organization_id <= 0 THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: ID đơn vị mới không hợp lệ.';
        RETURN;
    END IF;

    IF p_employee_ids IS NULL OR array_length(p_employee_ids, 1) IS NULL THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: Danh sách nhân viên trống.';
        RETURN;
    END IF;

    -- Kiểm tra chức danh mới có hợp lệ không (is_active = TRUE)
    IF NOT EXISTS (
        SELECT 1 FROM job_titles jt 
        WHERE jt.id = p_new_job_title_id 
        AND jt.is_active = TRUE
    ) THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: Chức danh mới không hợp lệ hoặc đã bị vô hiệu hóa.';
        RETURN;
    END IF;

    -- Kiểm tra chức danh mới có hợp lệ không (is_active = TRUE)
    IF NOT EXISTS (
        SELECT 1 FROM organizations org 
        WHERE org.id = p_new_organization_id 
        AND org.is_active = TRUE
    ) THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: Đơn vị mới không hợp lệ hoặc đã bị vô hiệu hóa.';
        RETURN;
    END IF;

    -- Kiểm tra chức danh mới có thuộc đơn vị mới không
    IF NOT EXISTS (
        SELECT 1 
        FROM job_title_organizations jto 
        WHERE jto.job_title_id = p_new_job_title_id 
        AND jto.org_id = p_new_organization_id 
        AND jto.is_active = TRUE
    ) THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: Chức danh mới không thuộc đơn vị được chọn hoặc đã bị vô hiệu hóa.';
        RETURN;
    END IF;


    IF p_manager_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_manager_id AND date_resign IS NULL) THEN
            RETURN QUERY SELECT stt_err, 'Lỗi: Người quản lý trực tiếp không tồn tại hoặc đã nghỉ việc';
            RETURN;
        END IF;
    END IF;

    SELECT value INTO v_job_change_type
    FROM enum_lookup WHERE id = p_job_change_type_id;


    SELECT location_id INTO v_location_id 
    FROM organizations WHERE id = p_new_organization_id;

    FOR v_employee_id IN SELECT unnest(p_employee_ids)
    LOOP
        -- Ghi log work_histories
        RAISE NOTICE 'Ghi log work_histories chuyển công việc nhân viên ID = %...', v_employee_id;
        
        
        SELECT w.status, w.message
        INTO v_work_status, v_work_message
        FROM work_histories_insert(
            v_employee_id,
            p_end_date_change_old,
            p_work_note
        ) AS w;

        IF NOT v_work_status THEN
            RETURN QUERY SELECT stt_err, FORMAT('Insert work_histories thất bại cho nhân viên ID %s: %s', v_employee_id, v_work_message);
            RETURN;
        END IF;

        -- Cập nhật employees từng nhân viên
        UPDATE employees
        SET 
            job_change_type = v_job_change_type,
            job_title_id = p_new_job_title_id,
            organization_id = p_new_organization_id,
            start_date_change = p_start_date_change,
            decision_signer = p_decision_signer,
            decision_no = p_decision_no,
            decision_sign_date = p_decision_sign_date,
            work_note = p_work_note,
            work_location_id = v_location_id,
            employee_type = p_employee_type
        WHERE id = v_employee_id
        AND job_title_id <> p_new_job_title_id;  -- chỉ update nếu khác job cũ
        
        -- Nếu update thành công
        IF FOUND THEN
            v_updated_count := v_updated_count + 1;
        END IF;

        -- Sau update, ghi log lịch sử nhân viên
        RAISE NOTICE 'Ghi log lịch sử nhân viên ID = %...', v_employee_id;
        PERFORM history_employees(v_employee_id, 'UPDATE_CHANGE_JOB');
    END LOOP;


    IF v_updated_count = 0 THEN
        RETURN QUERY SELECT stt_suc, 'Tất cả các nhân viên đang ở chức danh hiện tại.';
    ELSE
        RETURN QUERY SELECT stt_suc, FORMAT('%s nhân viên đã được cập nhật chức danh thành công.', v_updated_count);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT stt_err, 'Lỗi: ' || SQLERRM;
END;$$;


ALTER FUNCTION public.employee_job_title_update(p_new_job_title_id integer, p_new_organization_id integer, p_employee_ids integer[], p_decision_signer text, p_decision_no character varying, p_decision_sign_date date, p_end_date_change_old date, p_start_date_change date, p_job_change_type_id integer, p_work_note character varying, p_manager_id integer, p_employee_type public.employee_types, p_reason text) OWNER TO postgres;

--
-- Name: employee_managers_get(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_managers_get(p_emp_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    v_org_id      INTEGER;
    v_org_level   INTEGER;
    v_managers    JSONB;
    error_details JSONB := '[]'::JSONB;
    v_result      JSONB;
BEGIN
    -- 1. Lấy schema từ JWT và set search_path
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- 2. Validate nhân viên và lấy organization_id
    SELECT organization_id INTO v_org_id
    FROM employees
    WHERE id = p_emp_id;
    IF NOT FOUND THEN
        error_details := error_details || jsonb_build_object(
            'field', 'emp_id',
            'message_error', 'Employee not found'
        );
        RETURN jsonb_build_object(
            'code', 404,
            'status', false,
            'message', 'Employee not found',
            'errors', error_details
        );
    END IF;

    -- 3. Tính cấp độ của tổ chức
    WITH RECURSIVE org_path AS (
        SELECT id, parent_org_id, 1 AS level
        FROM organizations
        WHERE id = v_org_id

        UNION ALL

        SELECT o.id, o.parent_org_id, p.level + 1
        FROM organizations o
        JOIN org_path p ON o.id = p.parent_org_id
    )
    SELECT MAX(level) INTO v_org_level
    FROM org_path;

    -- 4. Xây dựng v_managers dựa trên v_org_level
    IF v_org_level <= 2 THEN
        -- Nếu cấp <= 2, chỉ lấy thông tin của chính tổ chức đó
        SELECT jsonb_build_array(
            jsonb_build_object(
                'id', o.id,
                'name', o.name,
                'direct_manager', CASE
                    WHEN o.direct_manager_id IS NOT NULL THEN 
                        jsonb_build_object('id', dm.id, 'name', dm.full_name)
                    ELSE NULL END,
                'general_manager', CASE
                    WHEN o.general_manager_id IS NOT NULL THEN 
                        jsonb_build_object('id', gm.id, 'name', gm.full_name)
                    ELSE NULL END
            )
        ) INTO v_managers
        FROM organizations o
        LEFT JOIN employees dm ON o.direct_manager_id = dm.id
        LEFT JOIN employees gm ON o.general_manager_id = gm.id
        WHERE o.id = v_org_id;
    ELSIF v_org_level = 3 THEN
        -- Nếu cấp = 3, lấy chính nó và 1 cấp cha
        WITH RECURSIVE org_hierarchy AS (
            SELECT 
                o.id, o.name, o.parent_org_id,
                o.direct_manager_id, o.general_manager_id,
                1 AS level
            FROM organizations o
            WHERE o.id = v_org_id

            UNION ALL

            SELECT 
                p.id, p.name, p.parent_org_id,
                p.direct_manager_id, p.general_manager_id,
                h.level + 1
            FROM organizations p
            JOIN org_hierarchy h ON p.id = h.parent_org_id
            WHERE h.level < 2  -- Chỉ lấy 1 cấp cha
        )
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', h.id,
                'name', h.name,
                'direct_manager', CASE
                    WHEN h.direct_manager_id IS NOT NULL THEN 
                        jsonb_build_object('id', dm.id, 'name', dm.full_name)
                    ELSE NULL END,
                'general_manager', CASE
                    WHEN h.general_manager_id IS NOT NULL THEN 
                        jsonb_build_object('id', gm.id, 'name', gm.full_name)
                    ELSE NULL END
            )
            ORDER BY h.level DESC
        ) INTO v_managers
        FROM org_hierarchy h
        LEFT JOIN employees dm ON h.direct_manager_id = dm.id
        LEFT JOIN employees gm ON h.general_manager_id = gm.id;
    ELSE
        -- Nếu cấp > 3, lấy 2 cấp cha trên
        WITH RECURSIVE org_hierarchy AS (
            SELECT 
                o.id, o.name, o.parent_org_id,
                o.direct_manager_id, o.general_manager_id,
                1 AS level
            FROM organizations o
            WHERE o.id = v_org_id

            UNION ALL

            SELECT 
                p.id, p.name, p.parent_org_id,
                p.direct_manager_id, p.general_manager_id,
                h.level + 1
            FROM organizations p
            JOIN org_hierarchy h ON p.id = h.parent_org_id
            WHERE h.level < 3  -- Chỉ lấy 2 cấp cha
        )
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', h.id,
                'name', h.name,
                'direct_manager', CASE
                    WHEN h.direct_manager_id IS NOT NULL THEN 
                        jsonb_build_object('id', dm.id, 'name', dm.full_name)
                    ELSE NULL END,
                'general_manager', CASE
                    WHEN h.general_manager_id IS NOT NULL THEN 
                        jsonb_build_object('id', gm.id, 'name', gm.full_name)
                    ELSE NULL END
            )
            ORDER BY h.level DESC
        ) INTO v_managers
        FROM org_hierarchy h
        LEFT JOIN employees dm ON h.direct_manager_id = dm.id
        LEFT JOIN employees gm ON h.general_manager_id = gm.id
        WHERE h.parent_org_id IS NOT NULL;
    END IF;

    -- 5. Trả về kết quả chung
    WITH employee_data AS (
        SELECT 
            e.id,
            e.full_name,
            e.emp_code,
            e.avatar,
            e.email_internal,
            e.phone,
            e.date_join,
            CASE
                WHEN e.date_resign IS NOT NULL THEN 'terminated'::text
                WHEN e.date_probation_start IS NOT NULL AND e.date_official_start IS NULL THEN 'trial'::text
                WHEN e.date_join IS NOT NULL AND e.date_resign IS NULL THEN 'active'::text
                ELSE 'unknown'::text
            END as status
        FROM employees e
        WHERE e.id = p_emp_id
    )
    SELECT jsonb_build_object(
        'code',    200,
        'status',  true,
        'message', 'Successfully retrieved employee managers',
        'data', jsonb_build_object(
            'employee_id',   ed.id,
            'emp_code', ed.emp_code,
            'employee_name', ed.full_name,
            'employee_code', ed.emp_code,
            'status', ed.status,
            'email_internal', ed.email_internal,
            'phone', ed.phone,
            'date_join', ed.date_join,
            'avatar_url', ed.avatar,
            'managers',      COALESCE(v_managers, '[]'::jsonb)
        )
    ) INTO v_result
    FROM employee_data ed;

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code',    500,
            'status',  false,
            'message', 'Internal server error',
            'errors',  jsonb_build_array(
                jsonb_build_object(
                    'field',         'general',
                    'message_error', SQLERRM
                )
            )
        );
END;
$$;


ALTER FUNCTION public.employee_managers_get(p_emp_id integer) OWNER TO postgres;

--
-- Name: employee_position_update(integer, integer, integer, integer, integer, integer, character varying, character varying, date, text, date, date, public.employee_types, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_position_update(p_emp_id integer, p_job_title_id integer, p_organization_id integer, p_change_type_id integer, p_location_id integer, p_manager_id integer, p_decision_no character varying, p_decision_signer character varying, p_decision_sign_date date, p_reason text, p_start_date_change date, p_end_date_change date DEFAULT NULL::date, p_employee_type public.employee_types DEFAULT '1'::public.employee_types, p_work_note text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$DECLARE
    v_validation JSONB;
    V_job_change_type VARCHAR;
    v_end_date_change   DATE;
BEGIN
    -- 1. Thiết lập schema tenant
    EXECUTE format('SET search_path TO %I', current_setting('request.jwt.claims', true)::jsonb->>'schema');
 
    -- 2. Gọi validate chung
    v_validation := validate_employee_position_update(
        p_emp_id, p_job_title_id, p_organization_id, p_change_type_id,
        p_location_id, p_decision_no, p_decision_signer, p_decision_sign_date,
        p_start_date_change, p_end_date_change, p_manager_id,
        p_reason, p_work_note
    );
    IF v_validation->>'status' = 'false' THEN
        RETURN v_validation;
    END IF;
 
    -- 3. Lấy lại change_type_value để dùng trong cập nhật
    -- Lấy loại thay đổi
    SELECT end_date_change INTO v_end_date_change
    FROM employees WHERE id = p_emp_id;
 
    SELECT value INTO v_job_change_type
    FROM enum_lookup WHERE id = p_change_type_id;
 
    -- 4. Thực hiện insert work_history, update employees và history
    BEGIN
        PERFORM work_histories_insert(p_emp_id, v_end_date_change, p_reason);
 
        UPDATE employees
        SET
            job_title_id      = p_job_title_id,
            organization_id   = p_organization_id,
            work_location_id  = p_location_id,
            job_change_type   = v_job_change_type,
            decision_no       = p_decision_no,
            decision_signer   = p_decision_signer,
            decision_sign_date= p_decision_sign_date,
            start_date_change = p_start_date_change,
            employee_type     = p_employee_type,
            end_date_change =  p_end_date_change,
            manager_id        = p_manager_id,
            work_note         = p_work_note
        WHERE id = p_emp_id;
 
        PERFORM history_employees(p_emp_id, 'UPDATE_POSITION_EMPLOYEE');
 
        RETURN jsonb_build_object(
            'code',   200,
            'status', true,
            'message','Cập nhật vị trí công việc thành công'
        );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN jsonb_build_object(
                'code',    500,
                'status',  false,
                'message', 'Lỗi hệ thống',
                'errors',  jsonb_build_array(
                    jsonb_build_object('field','general','message_error', SQLERRM)
                )
            );
    END;
END;$$;


ALTER FUNCTION public.employee_position_update(p_emp_id integer, p_job_title_id integer, p_organization_id integer, p_change_type_id integer, p_location_id integer, p_manager_id integer, p_decision_no character varying, p_decision_signer character varying, p_decision_sign_date date, p_reason text, p_start_date_change date, p_end_date_change date, p_employee_type public.employee_types, p_work_note text) OWNER TO postgres;

--
-- Name: employee_quit_job(integer, date, text, character varying, date, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_quit_job(p_employee_id integer, p_date_resign date, p_decision_signer text, p_decision_no character varying, p_decision_sign_date date, p_job_change_type_id integer, p_work_note character varying) RETURNS TABLE(status text, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_id INT;
    v_date_join DATE;
    tenant_schema TEXT;
    v_work_status BOOLEAN;
    v_work_message TEXT;
    v_chage_type_code TEXT;
BEGIN
    BEGIN

         -- Lấy schema từ JWT claims
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
        PERFORM set_config('search_path', tenant_schema, true);

        RAISE NOTICE '--- BẮT ĐẦU NGHIỆP VỤ NGHỈ VIỆC ---';
        RAISE NOTICE 'Kiểm tra nhân viên ID = %', p_employee_id;

        -- Kiểm tra nhân viên tồn tại và lấy ngày vào làm
        SELECT id, date_join
        INTO v_id, v_date_join
        FROM employees
        WHERE id = p_employee_id;

        IF v_id IS NULL THEN
            RAISE NOTICE 'Kiểm tra nhân viên ID = % không tồn tại.', p_employee_id;
            RETURN QUERY SELECT 'error', 'Nhân viên không tồn tại.';
            RETURN;
        END IF;

        RAISE NOTICE 'Nhân viên ID = % tồn tại. Ngày vào làm: %', p_employee_id, v_date_join;

        -- Kiểm tra ngày nghỉ hợp lệ
        IF p_date_resign < v_date_join THEN
            RAISE NOTICE 'Nhân viên ID = % ngày nghỉ % nhỏ hơn ngày vào làm %', p_employee_id, p_date_resign, v_date_join;
            RETURN QUERY SELECT 'error', 'Ngày nghỉ không được nhỏ hơn ngày vào làm.';
            RETURN;
        END IF;

        SELECT value INTO v_chage_type_code
        FROM enum_lookup WHERE id = p_job_change_type_id;

        RAISE NOTICE 'Tiến hành cập nhật thông tin nghỉ việc nhân viên ID = %...', p_employee_id;

        -- Gọi hàm cập nhật lịch sử nghỉ việc
        RAISE NOTICE 'Ghi log work_histories nghỉ việc nhân viên ID = %...', p_employee_id;
        SELECT w.status, w.message
        INTO v_work_status, v_work_message
        FROM work_histories_insert(
            p_employee_id,
            p_date_resign,
            p_work_note
        ) AS w;

        IF NOT v_work_status THEN
            RETURN QUERY SELECT 'error', 'Insert work_histories thất bại: ' || v_work_message;
            RETURN;
        END IF;

        -- Cập nhật nghỉ việc
        UPDATE employees
        SET 
            date_resign = p_date_resign,
            start_date_change = p_date_resign,
            end_date_change = p_date_resign,
            last_work_date = p_date_resign,
            decision_signer = p_decision_signer,
            decision_no = p_decision_no,
            decision_sign_date = p_decision_sign_date,
            job_change_type = v_chage_type_code,
            work_note = p_work_note
        WHERE id = p_employee_id;

        RAISE NOTICE 'Ghi log lịch sử nhân viên ID = %...', p_employee_id;
        PERFORM history_employees(p_employee_id, 'UPDATE_QUIT_JOB');

        RAISE NOTICE 'Hoàn tất cập nhật nghỉ việc.';
        RETURN QUERY SELECT 'success', 'Cập nhật nghỉ việc và ghi log thành công.';
    
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Lỗi ngoại lệ: %', SQLERRM;
        RETURN QUERY SELECT 'error', 'Đã xảy ra lỗi hệ thống: ' || SQLERRM;
    END;
END;$$;


ALTER FUNCTION public.employee_quit_job(p_employee_id integer, p_date_resign date, p_decision_signer text, p_decision_no character varying, p_decision_sign_date date, p_job_change_type_id integer, p_work_note character varying) OWNER TO postgres;

--
-- Name: employee_update(integer, character varying, character varying, character varying, public.gender, date, integer, integer, integer, integer, public.marital_statuses, integer, character varying, date, date, integer, character varying, date, text, public.education_level, character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, text, character varying, character varying, integer, character varying, integer, character varying, integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employee_update(p_id integer, p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_gender public.gender, p_dob date, p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no character varying, p_old_date_issue date, p_old_place_issue_id text, p_education_level public.education_level, p_degree_type character varying, p_institution character varying, p_major character varying, p_en_cert_id integer, p_it_cert_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_home_phone character varying, p_company_phone character varying, p_cif_code text, p_bank_account_no character varying, p_bank_name character varying, p_manager_id integer, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_date_join date) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_error_details JSONB := '[]'::JSONB;
    v_tenant_schema TEXT;
    v_full_name VARCHAR(100);
    v_validation_result JSONB;
BEGIN
    -- Get tenant schema from JWT
    v_tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', v_tenant_schema);

    -- Validate input data
    SELECT validate_employee_update(
        p_id,
        p_last_name,
        p_middle_name,
        p_first_name,
        p_gender,
        p_dob,
        p_hometown_provinces_id,
        p_ethnicity_id,
        p_nationality_id,
        p_religion_id,
        p_marital_status,
        p_occupation_id,
        p_identity_no,
        p_date_issue,
        p_date_identity_expiry,
        p_place_issue_id,
        p_old_identity_no,
        p_old_date_issue,
        p_old_place_issue_id,
        p_education_level,
        p_degree_type,
        p_institution,
        p_major,
        p_en_cert_id,
        p_it_cert_id,
        p_email_internal,
        p_email_external,
        p_phone,
        p_secondary_phone,
        p_home_phone,
        p_company_phone,
        p_cif_code,
        p_bank_account_no,
        p_bank_name,
        p_manager_id,
        p_permanent_address,
        p_permanent_district_id,
        p_temporary_address,
        p_temporary_district_id,
        p_date_join
    ) INTO v_validation_result;

    -- Check validation result
    IF NOT (v_validation_result->>'status')::BOOLEAN THEN
        RETURN v_validation_result;
    END IF;

    -- Construct full name
    v_full_name := CONCAT(p_last_name, ' ', p_middle_name, ' ', p_first_name);

    -- Update employee information
    UPDATE employees
    SET
        last_name = p_last_name,
        middle_name = p_middle_name,
        first_name = p_first_name,
        full_name = v_full_name,
        gender = p_gender,
        dob = p_dob,
        hometown_provinces_id = p_hometown_provinces_id,
        ethnicity_id = p_ethnicity_id,
        nationality_id = p_nationality_id,
        religion_id = p_religion_id,
        marital_status = p_marital_status,
        occupation_id = p_occupation_id,
        identity_no = p_identity_no,
        date_issue = p_date_issue,
        date_identity_expiry = p_date_identity_expiry,
        place_issue_id = p_place_issue_id,
        old_identity_no = p_old_identity_no,
        old_date_issue = p_old_date_issue,
        old_place_issue_id = p_old_place_issue_id,
        education_level = p_education_level,
        degree_type = p_degree_type,
        institution = p_institution,
        major = p_major,
        en_cert_id = p_en_cert_id,
        it_cert_id = p_it_cert_id,
        email_internal = p_email_internal,
        email_external = p_email_external,
        phone = p_phone,
        secondary_phone = p_secondary_phone,
        home_phone = p_home_phone,
        company_phone = p_company_phone,
        cif_code = p_cif_code,
        bank_account_no = p_bank_account_no,
        bank_name = p_bank_name,
        manager_id = p_manager_id,
        permanent_address = p_permanent_address,
        permanent_district_id = p_permanent_district_id,
        temporary_address = p_temporary_address,
        temporary_district_id = p_temporary_district_id,
        date_join = p_date_join
    WHERE id = p_id;

    -- Gọi history_employees để ghi log
    PERFORM history_employees(p_id, 'UPDATE_EMPLOYEE');

    -- Return success response
    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Cập nhật thông tin cá nhân thành công'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code', 500,
            'status', false,
            'message', 'Lỗi hệ thống: ' || SQLERRM
        );
END;
$$;


ALTER FUNCTION public.employee_update(p_id integer, p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_gender public.gender, p_dob date, p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no character varying, p_old_date_issue date, p_old_place_issue_id text, p_education_level public.education_level, p_degree_type character varying, p_institution character varying, p_major character varying, p_en_cert_id integer, p_it_cert_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_home_phone character varying, p_company_phone character varying, p_cif_code text, p_bank_account_no character varying, p_bank_name character varying, p_manager_id integer, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_date_join date) OWNER TO postgres;

--
-- Name: employees_export(integer, integer, text, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employees_export(p_root_org_id integer DEFAULT NULL::integer, p_job_title_id integer DEFAULT NULL::integer, p_status_filter text DEFAULT NULL::text, p_date date DEFAULT CURRENT_DATE) RETURNS TABLE(id integer, emp_code character varying, emp_code_old text, nationality character varying, occupation character varying, last_name character varying, middle_name character varying, first_name character varying, full_name character varying, gender public.gender, religion character varying, ethnicity character varying, temporary_address character varying, temporary_district character varying, permanent_address character varying, permanent_district character varying, email_internal character varying, email_external character varying, phone character varying, secondary_phone character varying, home_phone character varying, company_phone character varying, profile_introduced character varying, job_title character varying, organization character varying, work_location character varying, note text, old_identity_no character varying, old_date_issue date, old_place_issue text, identity_type character varying, identity_no character varying, date_issue date, date_identity_expiry date, place_issue character varying, date_join date, date_probation_start date, date_official_start date, date_resign date, last_work_date date, blood_group public.bloodgroup, blood_pressure character varying, height_cm numeric, weight_kg numeric, job_change_type character varying, manager_name character varying, decision_no character varying, decision_signer character varying, decision_sign_date date, start_date_change date, end_date_change date, work_note character varying, tax_no character varying, cif_code text, bank_account_no character varying, bank_name character varying, is_social_insurance boolean, is_unemployment_insurance boolean, is_life_insurance boolean, party_start_date date, union_youth_start_date date, party_official_date date, military_start_date date, military_end_date date, military_highest_rank character varying, is_old_regime boolean, is_wounded_soldier boolean, en_cert character varying, it_cert character varying, degree_type character varying, academic text, institution character varying, faculty character varying, major character varying, graduation_year date, employee_type public.employee_types, hometown_province character varying, marital_status public.marital_statuses, education_level public.education_level, dob date, status text, avatar text, recruitment text, union_start_date date, union_fee_date date, union_decision_no text, union_decision_date date, union_appointment_no text, union_position text, union_organization_name character varying, union_status public.statusunion, union_activity text, created_at timestamp with time zone, created_by text, modified_at timestamp with time zone, modified_by text)
    LANGUAGE plpgsql
    AS $$DECLARE
  tenant_schema TEXT;
BEGIN
  -- Set the schema dynamically based on JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb ->> 'schema';
  EXECUTE format('SET LOCAL search_path TO %I', tenant_schema);

  RETURN QUERY
  WITH RECURSIVE subtree(org_id) AS (
    SELECT o.id
    FROM organizations o
    WHERE o.id = p_root_org_id
      AND p_root_org_id IS NOT NULL
    UNION ALL
    SELECT c.id
    FROM organizations c
    JOIN subtree s ON c.parent_org_id = s.org_id
  ),
  filtered_employees AS (
    SELECT
      ev.id,
      ev.emp_code,
      ev.emp_code_old,
      ev.nationality,
      ev.occupation,
      ev.last_name,
      ev.middle_name,
      ev.first_name,
      ev.full_name,
      ev.gender,
      ev.religion,
      ev.ethnicity,
      ev.temporary_address,
      ev.temporary_district,
      ev.permanent_address,
      ev.permanent_district,
      ev.email_internal,
      ev.email_external,
      ev.phone,
      ev.secondary_phone,
      ev.home_phone,
      ev.company_phone,
      ev.profile_introduced,
      ev.job_title,
      ev.organization,
      ev.work_location,
      ev.note,
      ev.old_identity_no,
      ev.old_date_issue,
      ev.old_place_issue_id,
      ev.identity_type,
      ev.identity_no,
      ev.date_issue,
      ev.date_identity_expiry,
      ev.place_issue,
      ev.date_join,
      ev.date_probation_start,
      ev.date_official_start,
      ev.date_resign,
      ev.last_work_date,
      ev.blood_group,
      ev.blood_pressure,
      ev.height_cm,
      ev.weight_kg,
      ev.job_change,
      ev.manager_name,
      ev.decision_no,
      ev.decision_signer,
      ev.decision_sign_date,
      ev.start_date_change,
      ev.end_date_change,
      ev.work_note,
      ev.tax_no,
      ev.cif_code,
      ev.bank_account_no,
      ev.bank_name,
      ev.is_social_insurance,
      ev.is_unemployment_insurance,
      ev.is_life_insurance,
      ev.party_start_date,
      ev.union_youth_start_date,
      ev.party_official_date,
      ev.military_start_date,
      ev.military_end_date,
      ev.military_highest_rank,
      ev.is_old_regime,
      ev.is_wounded_soldier,
      ev.en_cert,
      ev.it_cert,
      ev.degree_type,
      ev.academic,
      ev.institution,
      ev.faculty,
      ev.major,
      ev.graduation_year,
      ev.employee_type,
      ev.hometown_province,
      ev.marital_status,
      ev.education_level,
      ev.dob,
      ev.avatar,
      ev.recruitment,
      ev.union_start_date,
      ev.union_fee_date,
      ev.union_decision_no,
      ev.union_decision_date,
      ev.union_appointment_no,
      ev.union_position,
      ev.union_organization_name,
      ev.union_status,
      ev.union_activity,
      ev.created_at,
      ev.created_by,
      ev.modified_at,
      ev.modified_by,
      CASE
        WHEN (ev.date_resign IS NOT NULL AND ev.date_resign < p_date + INTERVAL '1 day')
        THEN 'terminated'

        WHEN ev.date_resign IS NOT NULL
             AND ev.date_join IS NOT NULL
             AND (ev.date_probation_start IS NULL AND ev.date_official_start IS NULL)
        THEN 'declined'
        
        WHEN ev.date_probation_start IS NOT NULL
             AND ev.date_official_start IS NULL
        THEN 'trial'
        
        WHEN ev.date_join IS NOT NULL
             AND ev.date_join > p_date
             AND (ev.date_probation_start IS NULL AND ev.date_official_start IS NULL) OR (ev.date_probation_start > p_date AND ev.date_official_start > p_date)
             AND ev.date_resign IS NULL OR ev.date_resign > p_date
        THEN 'waiting'
        
        WHEN ev.date_join IS NOT NULL
             AND ev.date_join <= p_date
             AND (ev.date_resign IS NULL OR ev.date_resign > p_date)
        THEN 'active'
        
        ELSE 'unknown'
      END AS computed_status
    FROM employees_export_full_view ev
    WHERE
      -- Organization filter
      (p_root_org_id IS NULL OR ev.organization_id IN (SELECT org_id FROM subtree))
      -- Job title filter
      AND (p_job_title_id IS NULL OR ev.job_title_id = p_job_title_id)
  )
  SELECT
    fe.id,
    fe.emp_code,
    fe.emp_code_old,
    fe.nationality,
    fe.occupation,
    fe.last_name,
    fe.middle_name,
    fe.first_name,
    fe.full_name,
    fe.gender,
    fe.religion,
    fe.ethnicity,
    fe.temporary_address,
    fe.temporary_district,
    fe.permanent_address,
    fe.permanent_district,
    fe.email_internal,
    fe.email_external,
    fe.phone,
    fe.secondary_phone,
    fe.home_phone,
    fe.company_phone,
    fe.profile_introduced,
    fe.job_title,
    fe.organization,
    fe.work_location,
    fe.note,
    fe.old_identity_no,
    fe.old_date_issue,
    fe.old_place_issue_id,
    fe.identity_type,
    fe.identity_no,
    fe.date_issue,
    fe.date_identity_expiry,
    fe.place_issue,
    fe.date_join,
    fe.date_probation_start,
    fe.date_official_start,
    fe.date_resign,
    fe.last_work_date,
    fe.blood_group,
    fe.blood_pressure,
    fe.height_cm,
    fe.weight_kg,
    fe.job_change,
    fe.manager_name,
    fe.decision_no,
    fe.decision_signer,
    fe.decision_sign_date,
    fe.start_date_change,
    fe.end_date_change,
    fe.work_note,
    fe.tax_no,
    fe.cif_code,
    fe.bank_account_no,
    fe.bank_name,
    fe.is_social_insurance,
    fe.is_unemployment_insurance,
    fe.is_life_insurance,
    fe.party_start_date,
    fe.union_youth_start_date,
    fe.party_official_date,
    fe.military_start_date,
    fe.military_end_date,
    fe.military_highest_rank,
    fe.is_old_regime,
    fe.is_wounded_soldier,
    fe.en_cert,
    fe.it_cert,
    fe.degree_type,
    fe.academic,
    fe.institution,
    fe.faculty,
    fe.major,
    fe.graduation_year,
    fe.employee_type,
    fe.hometown_province,
    fe.marital_status,
    fe.education_level,
    fe.dob,
    fe.computed_status AS status,
    fe.avatar,
    fe.recruitment,
    fe.union_start_date,
    fe.union_fee_date,
    fe.union_decision_no,
    fe.union_decision_date,
    fe.union_appointment_no,
    fe.union_position,
    fe.union_organization_name,
    fe.union_status,
    fe.union_activity,
    fe.created_at,
    fe.created_by,
    fe.modified_at,
    fe.modified_by
  FROM filtered_employees fe
  WHERE p_status_filter IS NULL OR fe.computed_status = p_status_filter;
END;$$;


ALTER FUNCTION public.employees_export(p_root_org_id integer, p_job_title_id integer, p_status_filter text, p_date date) OWNER TO postgres;

--
-- Name: employees_view_list(integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.employees_view_list(p_root_org_id integer DEFAULT NULL::integer, p_job_title_id integer DEFAULT NULL::integer, p_status_filter text DEFAULT NULL::text, p_keyword text DEFAULT NULL::text) RETURNS TABLE(id integer, organization_id integer, organization_name character varying, code character varying, full_name character varying, email_internal character varying, job_title_id integer, job_title_name character varying, job_position_id integer, job_position_name character varying, date_join date, gender public.gender, dob date, phone character varying, sort_order integer, status text, emp_code_old text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT và set LOCAL search_path
  tenant_schema := (
    current_setting('request.jwt.claims', true)::jsonb ->> 'schema'
  );
  EXECUTE format('SET LOCAL search_path TO %I', tenant_schema);
 
  RETURN QUERY
  WITH RECURSIVE subtree(org_id) AS (
    SELECT o.id
    FROM organizations o
    WHERE o.id = p_root_org_id
 
    UNION ALL
 
    SELECT c.id
    FROM organizations c
    JOIN subtree s ON c.parent_org_id = s.org_id
  )
  SELECT
    elv.id,
    elv.organization_id,
    elv.organization_name,
    elv.code,
    elv.full_name,
    elv.email_internal,
    elv.job_title_id,
    elv.job_title_name,
    jto.id             AS job_position_id,   -- thêm vào đây
    jto.job_position_name,            -- lấy từ bảng job_title_organizations
    elv.date_join,
    elv.gender,
    elv.dob,
    elv.phone,
    elv.sort_order,
    elv.status,
    elv.emp_code_old
  FROM employee_list_view elv
  LEFT JOIN job_title_organizations jto
    ON jto.job_title_id = elv.job_title_id
   AND jto.org_id       = elv.organization_id
  WHERE
    -- Nếu p_root_org_id NULL: lấy tất cả
    -- Ngược lại: chỉ lấy những organization_id nằm trong subtree
    (p_root_org_id IS NULL
      OR elv.organization_id IN (SELECT org_id FROM subtree)
    )
    AND (p_status_filter IS NULL OR elv.status = p_status_filter)
    AND (p_job_title_id IS NULL OR elv.job_title_id = p_job_title_id)
    AND (
      p_keyword IS NULL
      OR (
        public.unaccent_vi(elv.code) ILIKE '%' || public.unaccent_vi(p_keyword) || '%'
        OR public.unaccent_vi(elv.full_name) ILIKE '%' || public.unaccent_vi(p_keyword) || '%'
        OR public.unaccent_vi(elv.email_internal) ILIKE '%' || public.unaccent_vi(p_keyword) || '%'
      )
    );
END;
$$;


ALTER FUNCTION public.employees_view_list(p_root_org_id integer, p_job_title_id integer, p_status_filter text, p_keyword text) OWNER TO postgres;

--
-- Name: ensure_user_exists(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ensure_user_exists() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_user_id UUID := current_setting('request.jwt.claims', true)::jsonb->>'sub';
  v_name TEXT := current_setting('request.jwt.claims', true)::jsonb->>'name';
  v_preferred_username TEXT := current_setting('request.jwt.claims', true)::jsonb->>'preferred_username';
  v_email TEXT := current_setting('request.jwt.claims', true)::jsonb->>'email';
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  PERFORM set_config('search_path', tenant_schema, true);
  IF NOT EXISTS (
    SELECT 1 FROM users WHERE id = v_user_id
  ) THEN
    INSERT INTO users (id, name, preferred_username, email)
    VALUES (v_user_id, v_name, v_preferred_username, v_email);
  END IF;
END;
$$;


ALTER FUNCTION public.ensure_user_exists() OWNER TO postgres;

--
-- Name: external_experience_add(integer, text, character varying, character varying, date, date, numeric, numeric, character varying, character varying, character varying, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.external_experience_add(p_emp_id integer, p_position text, p_company_name character varying, p_address character varying, p_start_date date, p_end_date date, p_start_salary numeric, p_current_salary numeric, p_phone character varying, p_contact character varying, p_contact_position character varying, p_main_duty text, p_reason_leave text, p_note text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Log bắt đầu
  RAISE NOTICE '🎓 Bắt đầu thêm kinh nghiệm làm việc bên ngoài cho nhân viên ID %', p_emp_id;

  -- Kiểm tra nhân viên tồn tại
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Nhân viên không tồn tại';
    RETURN;
  END IF;

  -- Gọi validate_external_experience_input để kiểm tra đầu vào
  PERFORM validate_external_experience_input(
    p_company_name, p_start_date, p_end_date
  );

  -- Thêm bản ghi vào bảng external_experiences
  INSERT INTO external_experiences (
    emp_id, position, company_name, address, start_date, end_date,
    start_salary, current_salary, phone, contact, contact_position,
    main_duty, reason_leave, note
  )
  VALUES (
    p_emp_id, p_position, p_company_name, p_address, p_start_date, p_end_date,
    p_start_salary, p_current_salary, p_phone, p_contact, p_contact_position,
    p_main_duty, p_reason_leave, p_note
  );


  PERFORM history_employees(p_emp_id, 'ADD_EXTERNAL_EXPERIENCE');

  -- Log hoàn tất
  RAISE NOTICE '✅ Đã thêm kinh nghiệm làm việc bên ngoài và ghi log cho nhân viên ID %', p_emp_id;

  -- Trả về kết quả thành công
  RETURN QUERY SELECT true, '✅ Tạo kinh nghiệm làm việc bên ngoài thành công';
EXCEPTION WHEN OTHERS THEN
  -- Bắt lỗi và trả về thông báo lỗi
  RAISE NOTICE 'Lỗi: %', SQLERRM;
  RETURN QUERY SELECT false, SQLERRM;
END;
$$;


ALTER FUNCTION public.external_experience_add(p_emp_id integer, p_position text, p_company_name character varying, p_address character varying, p_start_date date, p_end_date date, p_start_salary numeric, p_current_salary numeric, p_phone character varying, p_contact character varying, p_contact_position character varying, p_main_duty text, p_reason_leave text, p_note text) OWNER TO postgres;

--
-- Name: external_experience_delete(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.external_experience_delete(p_id integer, p_emp_id integer) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RETURN QUERY SELECT false, 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra bản ghi và nhân viên có tồn tại
  IF NOT EXISTS (SELECT 1 FROM external_experiences WHERE id = p_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy bản ghi kinh nghiệm làm việc bên ngoài';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy nhân viên';
  END IF;

  -- Xóa dữ liệu
  DELETE FROM external_experiences WHERE id = p_id;

  -- Ghi log lịch sử nhân viên
  PERFORM history_employees(p_emp_id, 'DELETE_EXTERNAL_EXPERIENCE');

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Xóa kinh nghiệm làm việc bên ngoài thành công';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.external_experience_delete(p_id integer, p_emp_id integer) OWNER TO postgres;

--
-- Name: external_experience_update(integer, integer, text, character varying, character varying, date, date, numeric, numeric, character varying, character varying, character varying, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.external_experience_update(p_id integer, p_emp_id integer, p_position text, p_company_name character varying, p_address character varying, p_start_date date, p_end_date date, p_start_salary numeric, p_current_salary numeric, p_phone character varying, p_contact character varying, p_contact_position character varying, p_main_duty text, p_reason_leave text, p_note text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RETURN QUERY SELECT false, 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra bản ghi và nhân viên có tồn tại
  IF NOT EXISTS (SELECT 1 FROM external_experiences WHERE id = p_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy bản ghi kinh nghiệm làm việc bên ngoài';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy nhân viên';
  END IF;

  -- Kiểm tra logic ngày tháng
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
    RETURN QUERY SELECT false, 'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc';
  END IF;

  -- Cập nhật dữ liệu
  UPDATE external_experiences
  SET
    emp_id = p_emp_id,
    position = p_position,
    company_name = p_company_name,
    address = p_address,
    start_date = p_start_date,
    end_date = p_end_date,
    start_salary = p_start_salary,
    current_salary = p_current_salary,
    phone = p_phone,
    contact = p_contact,
    contact_position = p_contact_position,
    main_duty = p_main_duty,
    reason_leave = p_reason_leave,
    note = p_note
  WHERE id = p_id;

  -- Ghi log lịch sử nhân viên
  PERFORM history_employees(p_emp_id, 'UPDATE_EXTERNAL_EXPERIENCE');

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Cập nhật kinh nghiệm làm việc bên ngoài thành công và ghi log';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.external_experience_update(p_id integer, p_emp_id integer, p_position text, p_company_name character varying, p_address character varying, p_start_date date, p_end_date date, p_start_salary numeric, p_current_salary numeric, p_phone character varying, p_contact character varying, p_contact_position character varying, p_main_duty text, p_reason_leave text, p_note text) OWNER TO postgres;

--
-- Name: family_dependent_add(integer, text, character varying, integer, text, text, text, text, text, text, boolean, text, text, integer, integer, boolean, text, date, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.family_dependent_add(p_emp_id integer, p_full_name text, p_gender character varying, p_dob integer, p_address text, p_phone text, p_email text, p_identity_no text, p_identity_type text, p_tax_no text, p_is_tax_dependent boolean, p_occupation text, p_workplace text, p_relationship_type_id integer, p_relative_emp_id integer, p_is_dependent boolean, p_reason text, p_deduction_start_date date, p_deduction_end_date date, p_note text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Log bắt đầu
  RAISE NOTICE '🎓 Bắt đầu thêm người phụ thuộc cho nhân viên ID %', p_emp_id;

  -- Kiểm tra nhân viên tồn tại
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Nhân viên không tồn tại';
    RETURN;
  END IF;

  -- Gọi validate_family_dependent_input để kiểm tra đầu vào
  PERFORM validate_family_dependent_input(
    p_full_name, p_gender, p_dob, p_address, p_identity_no,
    p_identity_type, p_occupation, p_relationship_type_id
  );

  -- Thêm bản ghi vào bảng family_dependents
  INSERT INTO family_dependents (
    emp_id, full_name, gender, dob, address, phone, email, identity_no, identity_type,
    tax_no, is_tax_dependent, occupation, workplace, relationship_type_id, relative_emp_id,
    is_dependent, reason, deduction_start_date, deduction_end_date, note, created_at
  )
  VALUES (
    p_emp_id, p_full_name, p_gender::public.gender, p_dob, p_address, p_phone, p_email, p_identity_no, p_identity_type,
    p_tax_no, p_is_tax_dependent, p_occupation, p_workplace, p_relationship_type_id, p_relative_emp_id,
    p_is_dependent, p_reason, p_deduction_start_date, p_deduction_end_date, p_note, NOW()
  );

  -- Gọi history_employees để ghi log
  PERFORM history_employees(p_emp_id, 'ADD_FAMILY_DEPENDENT');

  -- Log hoàn tất
  RAISE NOTICE '✅ Đã thêm người phụ thuộc và ghi log cho nhân viên ID %', p_emp_id;

  -- Trả về kết quả thành công
  RETURN QUERY SELECT true, 'Tạo người phụ thuộc thành công';
EXCEPTION WHEN OTHERS THEN
  -- Bắt lỗi và trả về thông báo lỗi
  RAISE NOTICE 'Lỗi: %', SQLERRM;
  RETURN QUERY SELECT false, SQLERRM;
END;
$$;


ALTER FUNCTION public.family_dependent_add(p_emp_id integer, p_full_name text, p_gender character varying, p_dob integer, p_address text, p_phone text, p_email text, p_identity_no text, p_identity_type text, p_tax_no text, p_is_tax_dependent boolean, p_occupation text, p_workplace text, p_relationship_type_id integer, p_relative_emp_id integer, p_is_dependent boolean, p_reason text, p_deduction_start_date date, p_deduction_end_date date, p_note text) OWNER TO postgres;

--
-- Name: family_dependent_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.family_dependent_delete(p_id integer) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
  v_emp_id INT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra bản ghi có tồn tại và lấy emp_id
  SELECT emp_id INTO v_emp_id
  FROM family_dependents
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy bản ghi người phụ thuộc';
  END IF;

  -- Xóa dữ liệu
  DELETE FROM family_dependents WHERE id = p_id;

  -- Ghi log lịch sử nhân viên
  PERFORM history_employees(v_emp_id, 'DELETE_FAMILY_DEPENDENT');

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Xóa người phụ thuộc thành công';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.family_dependent_delete(p_id integer) OWNER TO postgres;

--
-- Name: family_dependent_update(integer, integer, text, character varying, integer, text, integer, text, text, text, text, text, boolean, text, text, integer, boolean, text, date, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.family_dependent_update(p_id integer, p_emp_id integer, p_full_name text, p_gender character varying, p_dob integer, p_address text, p_relationship_type_id integer, p_phone text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_identity_no text DEFAULT NULL::text, p_identity_type text DEFAULT NULL::text, p_tax_no text DEFAULT NULL::text, p_is_tax_dependent boolean DEFAULT NULL::boolean, p_occupation text DEFAULT NULL::text, p_workplace text DEFAULT NULL::text, p_relative_emp_id integer DEFAULT NULL::integer, p_is_dependent boolean DEFAULT NULL::boolean, p_reason text DEFAULT NULL::text, p_deduction_start_date date DEFAULT NULL::date, p_deduction_end_date date DEFAULT NULL::date, p_note text DEFAULT NULL::text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra bản ghi và nhân viên có tồn tại
  IF NOT EXISTS (SELECT 1 FROM family_dependents WHERE id = p_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy bản ghi người phụ thuộc';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy nhân viên';
  END IF;

  -- Cập nhật dữ liệu
  UPDATE family_dependents
  SET
    full_name = p_full_name,
    gender = p_gender::public.gender,
    dob = p_dob,
    address = p_address,
    phone = p_phone,
    email = p_email,
    identity_no = p_identity_no,
    identity_type = p_identity_type,
    tax_no = p_tax_no,
    is_tax_dependent = p_is_tax_dependent,
    occupation = p_occupation,
    workplace = p_workplace,
    relationship_type_id = p_relationship_type_id,
    relative_emp_id = p_relative_emp_id,
    is_dependent = p_is_dependent,
    reason = p_reason,
    deduction_start_date = p_deduction_start_date,
    deduction_end_date = p_deduction_end_date,
    note = p_note,
    modified_at = NOW()
  WHERE id = p_id;

  -- Ghi log lịch sử nhân viên
  PERFORM history_employees(p_emp_id, 'UPDATE_FAMILY_DEPENDENT');

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Cập nhật người phụ thuộc thành công';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.family_dependent_update(p_id integer, p_emp_id integer, p_full_name text, p_gender character varying, p_dob integer, p_address text, p_relationship_type_id integer, p_phone text, p_email text, p_identity_no text, p_identity_type text, p_tax_no text, p_is_tax_dependent boolean, p_occupation text, p_workplace text, p_relative_emp_id integer, p_is_dependent boolean, p_reason text, p_deduction_start_date date, p_deduction_end_date date, p_note text) OWNER TO postgres;

--
-- Name: feature_build_tree(integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.feature_build_tree(p_parent_id integer, p_current_depth integer, p_max_depth integer, p_search_by_is_active boolean DEFAULT NULL::boolean) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$DECLARE
    result JSONB;
BEGIN
    IF p_current_depth > p_max_depth THEN
        RETURN '[]'::JSONB;
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id', f.id,
            'code', f.code,
            'name', f.name,
            'description', f.description,
            'is_active', f.is_active,
            'children', feature_build_tree(
                            f.id,
                            p_current_depth + 1,
                            p_max_depth,
                            p_search_by_is_active
                        )
        )
    )
    INTO result
    FROM features f
    WHERE 
        (
            (p_parent_id IS NULL AND f.parent_id IS NULL)
            OR (p_parent_id IS NOT NULL AND f.parent_id = p_parent_id)
        )
        AND (p_search_by_is_active IS NULL OR f.is_active = p_search_by_is_active);

    RETURN COALESCE(result, '[]'::JSONB);
END;$$;


ALTER FUNCTION public.feature_build_tree(p_parent_id integer, p_current_depth integer, p_max_depth integer, p_search_by_is_active boolean) OWNER TO postgres;

--
-- Name: feature_build_tree_with_permissions(integer, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.feature_build_tree_with_permissions(p_role_id integer, p_parent_id integer DEFAULT NULL::integer, p_current_depth integer DEFAULT 1, p_max_depth integer DEFAULT NULL::integer, p_search_by_is_active boolean DEFAULT true) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    max_depth INT;
BEGIN
    IF p_max_depth IS NULL THEN
        max_depth := feature_get_max_depth();
    ELSE
        max_depth := p_max_depth;
    END IF;

    IF p_current_depth > max_depth THEN
        RETURN '[]'::JSONB;
    END IF;

    WITH raw_nodes AS (
        SELECT
            f.id,
            f.code,
            f.name,
            f.description,
            f.is_active,
            (
                SELECT jsonb_agg(a.code)
                FROM role_permission rp
                JOIN actions a ON a.id = rp.action_id
                WHERE rp.role_id = p_role_id
                AND rp.feature_id = f.id
            ) AS permissions,
            feature_build_tree_with_permissions(
                p_role_id,
                f.id,
                p_current_depth + 1,
                p_max_depth,
                p_search_by_is_active
            ) AS children
        FROM features f
        WHERE 
            ( (p_parent_id IS NULL AND f.parent_id IS NULL) OR (p_parent_id IS NOT NULL AND f.parent_id = p_parent_id) )
            AND (p_search_by_is_active IS NULL OR f.is_active = p_search_by_is_active)
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'code', code,
            'name', name,
            'description', description,
            'is_active', is_active,
            'permissions', permissions,
            'children', children
        )
    )
    INTO result
    FROM raw_nodes
    WHERE
        -- GIỮ node nếu:
        (permissions IS NOT NULL)
        OR
        (children IS NOT NULL AND jsonb_array_length(children) > 0);

    RETURN COALESCE(result, '[]'::JSONB);
END;
$$;


ALTER FUNCTION public.feature_build_tree_with_permissions(p_role_id integer, p_parent_id integer, p_current_depth integer, p_max_depth integer, p_search_by_is_active boolean) OWNER TO postgres;

--
-- Name: feature_build_tree_with_role_permissions(integer, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.feature_build_tree_with_role_permissions(p_role_id integer, p_parent_id integer DEFAULT NULL::integer, p_current_depth integer DEFAULT 1, p_max_depth integer DEFAULT NULL::integer, p_search_by_is_active boolean DEFAULT true) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    max_depth INT;
BEGIN
    IF p_max_depth IS NULL THEN
        max_depth := feature_get_max_depth();
    ELSE
        max_depth := p_max_depth;
    END IF;

    IF p_current_depth > max_depth THEN
        RETURN '[]'::JSONB;
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id', f.id,
            'code', f.code,
            'name', f.name,
            'description', f.description,
            'is_active', f.is_active,
            'permissions', (
                SELECT jsonb_agg(a.code)
                FROM role_permission rp
                JOIN actions a ON a.id = rp.action_id
                WHERE rp.role_id = p_role_id AND rp.feature_id = f.id
            ),
            'children', feature_build_tree_with_role_permissions(
                p_role_id,
                f.id,
                p_current_depth + 1,
                max_depth,
                p_search_by_is_active
            )
        )
    )
    INTO result
    FROM features f
    WHERE 
        (
            (p_parent_id IS NULL AND f.parent_id IS NULL)
            OR (p_parent_id IS NOT NULL AND f.parent_id = p_parent_id)
        )
        AND (p_search_by_is_active IS NULL OR f.is_active = p_search_by_is_active)
        AND EXISTS (
            SELECT 1
            FROM role_permission rp
            WHERE rp.role_id = p_role_id
              AND rp.feature_id = f.id
        );

    RETURN COALESCE(result, '[]'::JSONB);
END;
$$;


ALTER FUNCTION public.feature_build_tree_with_role_permissions(p_role_id integer, p_parent_id integer, p_current_depth integer, p_max_depth integer, p_search_by_is_active boolean) OWNER TO postgres;

--
-- Name: feature_get_max_depth(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.feature_get_max_depth() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    m INT;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    PERFORM set_config('search_path', tenant_schema, true);

    WITH RECURSIVE feature_cte AS (
        SELECT id, parent_id, 1 AS depth
        FROM features
        WHERE parent_id IS NULL

        UNION ALL

        SELECT f.id, f.parent_id, cte.depth + 1
        FROM features f
        JOIN feature_cte cte ON f.parent_id = cte.id
    )
    SELECT MAX(depth) INTO m FROM feature_cte;
    RETURN COALESCE(m, 0);
END;
$$;


ALTER FUNCTION public.feature_get_max_depth() OWNER TO postgres;

--
-- Name: feature_get_tree(boolean, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.feature_get_tree(p_is_active boolean DEFAULT true, p_max_depth integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    full_tree JSONB;
    max_depth INT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Nếu không truyền p_max_depth thì tự tính
    IF p_max_depth IS NULL THEN
        max_depth := feature_get_max_depth();
    ELSE
        max_depth := p_max_depth;
    END IF;

    -- Gọi đệ quy tạo cây JSON
    full_tree := feature_build_tree(NULL, 1, max_depth, p_is_active);
    RETURN full_tree;
END;
$$;


ALTER FUNCTION public.feature_get_tree(p_is_active boolean, p_max_depth integer) OWNER TO postgres;

--
-- Name: generate_new_emp_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_new_emp_code() RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE
  v_emp_code TEXT;
  v_max_num INTEGER;
BEGIN
  SELECT MAX(emp_code)
  INTO v_emp_code
  FROM employees;

  v_max_num := COALESCE(SUBSTRING(v_emp_code FROM 2)::INTEGER, 0);

  RETURN CONCAT('K', LPAD((v_max_num + 1)::TEXT, 5, '0'));
END;$$;


ALTER FUNCTION public.generate_new_emp_code() OWNER TO postgres;

--
-- Name: get_all_form_definitions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_all_form_definitions() RETURNS TABLE(code text, name text, json_schema jsonb, description text)
    LANGUAGE sql
    AS $$
  select
    code,
    name,
    json_schema,
    description
  from
    form_definition;
$$;


ALTER FUNCTION public.get_all_form_definitions() OWNER TO postgres;

--
-- Name: get_employee_count_and_comparison(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_employee_count_and_comparison() RETURNS TABLE(current_employee_count integer, previous_month_employee_count integer, percentage_change double precision)
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_date DATE := CURRENT_DATE;
    first_day_of_current_month DATE := DATE_TRUNC('month', current_date);
    last_day_of_previous_month DATE := first_day_of_current_month - INTERVAL '1 day';
BEGIN
    -- Tính số lượng nhân viên hiện tại (active tại current_date)
    SELECT COUNT(*) INTO current_employee_count
    FROM klb_prod_core.employees e
    WHERE
        e.date_join <= current_date
        AND (e.date_resign IS NULL OR e.date_resign > current_date)
        AND (e.date_probation_start IS NOT NULL OR e.date_official_start IS NOT NULL);

    -- Tính số lượng nhân viên tại cuối tháng trước (active tại last_day_of_previous_month)
    SELECT COUNT(*) INTO previous_month_employee_count
    FROM klb_prod_core.employees e
    WHERE
        e.date_join <= last_day_of_previous_month
        AND (e.date_resign IS NULL OR e.date_resign > last_day_of_previous_month)
        AND (e.date_probation_start IS NOT NULL OR e.date_official_start IS NOT NULL);

    -- Tính toán tỉ lệ phần trăm thay  
    IF previous_month_employee_count = 0 THEN
        percentage_change := NULL; -- Tránh chia cho 0
    ELSE
        percentage_change := ((current_employee_count - previous_month_employee_count)::FLOAT / previous_month_employee_count) * 100;
    END IF;

    RETURN QUERY SELECT current_employee_count, previous_month_employee_count, percentage_change;
END;
$$;


ALTER FUNCTION public.get_employee_count_and_comparison() OWNER TO postgres;

--
-- Name: get_feature_tree_json(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_feature_tree_json(p_id integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$DECLARE
  result JSON;
BEGIN
  WITH RECURSIVE feature_tree AS (
    SELECT
      id,
      code,
      name,
      description,
      parent_id
    FROM features
  ),
  tree (id, code, name, description, parent_id, children) AS (
    SELECT
      f.id,
      f.code,
      f.name,
      f.description,
      f.parent_id,
      '[]'::json AS children
    FROM feature_tree f
    WHERE (p_id IS NULL AND f.parent_id IS NULL)
       OR (p_id IS NOT NULL AND f.id = p_id)

    UNION ALL

    SELECT
      f.id,
      f.code,
      f.name,
      f.description,
      f.parent_id,
      '[]'::json
    FROM feature_tree f
    JOIN tree t ON f.parent_id = t.id
  ),
  json_tree AS (
    SELECT
      t1.id,
      t1.code,
      t1.name,
      t1.description,
      t1.parent_id,
      COALESCE(
        json_agg(
          jsonb_build_object(
            'id', t2.id,
            'code', t2.code,
            'name', t2.name,
            'description', t2.description,
            'children', t2.children
          )
        ) FILTER (WHERE t2.id IS NOT NULL),
        '[]'::jsonb
      ) AS children
    FROM tree t1
    LEFT JOIN tree t2 ON t2.parent_id = t1.id
    GROUP BY t1.id, t1.code, t1.name, t1.description, t1.parent_id, t1.children
  )
  SELECT json_agg(
    jsonb_build_object(
      'id', jt.id,
      'code', jt.code,
      'name', jt.name,
      'description', jt.description,
      'children', jt.children
    )
  )
  INTO result
  FROM json_tree jt
  WHERE (p_id IS NULL AND jt.parent_id IS NULL)
     OR (p_id IS NOT NULL AND jt.id = p_id);

  RETURN result;
END;$$;


ALTER FUNCTION public.get_feature_tree_json(p_id integer) OWNER TO postgres;

--
-- Name: get_filter_form_by_code(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_filter_form_by_code(form_code text) RETURNS TABLE(code text, name text, json_schema jsonb, description text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema text;
BEGIN
    -- Retrieve the tenant schema from JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    
    -- Raise an exception if the schema is not found in the JWT claims
    IF tenant_schema IS NULL THEN
        RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
    END IF;

    -- Set the schema search path for the current session
    PERFORM set_config('search_path', tenant_schema, true);

    -- Retrieve the form definition based on form_code with explicit type casting
    RETURN QUERY
    SELECT
        f.code::text,         -- Casting to text if it's varchar
        f.name::text,         -- Casting to text if it's varchar
        f.json_schema,
        f.description::text   -- Casting to text if it's varchar
    FROM
       form_definition f
    WHERE
        f.code = form_code;
END;
$$;


ALTER FUNCTION public.get_filter_form_by_code(form_code text) OWNER TO postgres;

--
-- Name: get_function_return_fields_json(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_function_return_fields_json(func_name text) RETURNS json
    LANGUAGE plpgsql STABLE
    AS $$DECLARE
    result JSON;
BEGIN
    SELECT json_agg(json_build_object(
        'field_name', param.parameter_name,
        'field_type', param.data_type
    ) ORDER BY param.ordinal_position)
    INTO result
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    JOIN information_schema.parameters param
        ON param.specific_name = p.proname || '_' || p.oid
    WHERE p.proname = func_name
      AND n.nspname = 'public'  -- optional: make this a parameter
      AND param.parameter_mode = 'OUT';

    RETURN COALESCE(result, '[]'::json);
END;$$;


ALTER FUNCTION public.get_function_return_fields_json(func_name text) OWNER TO postgres;

--
-- Name: get_grouped_active_reports_by_module(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_grouped_active_reports_by_module(module text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tenant_schema TEXT;
    result jsonb;
BEGIN
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    EXECUTE
    $sql$
      SELECT jsonb_agg(grouped)
      FROM (
        SELECT
          g.id,
          g.group_name,
          COALESCE(
            jsonb_agg(
              jsonb_build_object(
                'code', r.code,
                'filter_form_code', r.filter_form_code,
                'report_name', r.name,
                'json_schema', f.json_schema,
                'form_name', f.name
              )
            ) FILTER (WHERE r.id IS NOT NULL),
            '[]'::jsonb
          ) AS reports
        FROM
          report_group g
        LEFT JOIN
          report_definition r ON r.parent_id = g.id AND r.is_active = true
        LEFT JOIN
          form_definition f ON r.filter_form_code = f.code
        WHERE
          $1 = 'all' OR g.module = $1
        GROUP BY
          g.id
      ) grouped
    $sql$
    INTO result
    USING module;

    RETURN result;
END;
$_$;


ALTER FUNCTION public.get_grouped_active_reports_by_module(module text) OWNER TO postgres;

--
-- Name: get_org_parent(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_org_parent(p_org_id integer, p_org_level integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_managers JSONB;
    max_levels INTEGER;
BEGIN
    -- 1. Xác định số cấp cần lấy
    max_levels := CASE
        WHEN p_org_level <= 2 THEN 1
        WHEN p_org_level = 3 THEN 2
        ELSE 3
    END;

    -- 2. Duy nhất 1 CTE đệ quy, sau đó build JSON
    WITH RECURSIVE org_hierarchy AS (
        -- Bắt đầu từ tổ chức hiện tại
        SELECT
            o.id,
            o.name,
            o.parent_org_id,
            1 AS lvl
        FROM organizations o
        WHERE o.id = p_org_id

        UNION ALL

        -- Lấy dần cha theo cấp độ
        SELECT
            p.id,
            p.name,
            p.parent_org_id,
            h.lvl + 1
        FROM organizations p
        JOIN org_hierarchy h
          ON p.id = h.parent_org_id
        WHERE h.lvl < max_levels
    )
    SELECT jsonb_agg(obj) INTO v_managers
    FROM (
        SELECT jsonb_build_object(
                   'id', id,
                   'name', name
               ) AS obj
        FROM org_hierarchy
        -- Nếu muốn loại bỏ luôn tổ chức gốc lúc p_org_level > 2:
        -- WHERE NOT (lvl = 1 AND max_levels > 1)
        ORDER BY lvl DESC
    ) t;

    RETURN COALESCE(v_managers, '[]'::jsonb);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Lỗi khi lấy thông tin quản lý: %', SQLERRM;
END;
$$;


ALTER FUNCTION public.get_org_parent(p_org_id integer, p_org_level integer) OWNER TO postgres;

--
-- Name: get_organization_level(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_organization_level(p_org_id integer, p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_org_level INTEGER; -- Biến lưu cấp độ tổ chức
BEGIN
    -- Đặt search_path để truy vấn đúng schema của tenant
    EXECUTE format('SET search_path TO %I', p_schema);

    -- Sử dụng CTE đệ quy để duyệt cây tổ chức từ tổ chức hiện tại lên đến tổ chức gốc
    WITH RECURSIVE org_path AS (
        -- Bắt đầu từ tổ chức có ID là p_org_id, đặt cấp độ ban đầu là 1
        SELECT id, parent_org_id, 1 AS level
        FROM organizations
        WHERE id = p_org_id

        UNION ALL

        -- Tiếp tục lấy các tổ chức cha, tăng cấp độ lên 1 cho mỗi lần đệ quy
        SELECT o.id, o.parent_org_id, p.level + 1
        FROM organizations o
        JOIN org_path p ON o.id = p.parent_org_id
    )
    -- Lấy cấp độ cao nhất (số cấp từ tổ chức hiện tại đến gốc)
    SELECT MAX(level) INTO v_org_level
    FROM org_path;

    -- Trả về cấp độ tổ chức
    RETURN v_org_level;

EXCEPTION
    WHEN OTHERS THEN
        -- Xử lý lỗi nếu có vấn đề trong quá trình tính cấp độ
        RAISE EXCEPTION 'Lỗi khi tính cấp độ tổ chức: %', SQLERRM;
END;
$$;


ALTER FUNCTION public.get_organization_level(p_org_id integer, p_schema text) OWNER TO postgres;

--
-- Name: get_organizations(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_organizations() RETURNS TABLE(id integer, code character varying, name character varying, en_name character varying, parent_org_id integer, location_id integer, email character varying, parent_name character varying, location_name character varying, address character varying, districts_name character varying, provinces_name character varying, phone character varying, effective_date date, expired_date date, code_category character varying, category_name character varying, category_id integer, description text, is_active boolean, decision_no character varying, decision_date date, approve_struct text, cost_center_id integer, cost_center_name character varying, general_manager_id integer, general_manager_name character varying, direct_manager_id integer, direct_manager_name character varying, sub_org_count bigint, total_staff_allocation integer, employee_count integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := (
    current_setting('request.jwt.claims', true)::jsonb ->> 'schema'
  );
 
  -- Thiết lập search_path theo schema tenant
  EXECUTE format('SET LOCAL search_path TO %I', tenant_schema);
 
  -- Truy vấn dữ liệu từ view và gọi thêm 2 hàm
  RETURN QUERY
  SELECT
    v.*,
    get_total_staff_allocation(v.id),
    get_total_employees(v.id)
  FROM
    organization_details_view v;
END;
$$;


ALTER FUNCTION public.get_organizations() OWNER TO postgres;

--
-- Name: get_recent_org_logs(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_recent_org_logs(p_org_id integer) RETURNS TABLE(action text, log_date text, performed_by text, reason text, decision_no text, effective_date text, description text, version text)
    LANGUAGE plpgsql
    AS $$BEGIN
    RETURN QUERY
    SELECT 
        l.action::TEXT,
        TO_CHAR(l.log_date, 'YYYY-MM-DD')::TEXT,
        'Admin'::TEXT,
        COALESCE(l.reason, '-')::TEXT,
        COALESCE(l.decision_no, '-')::TEXT,
        TO_CHAR(l.effective_date, 'YYYY-MM-DD')::TEXT,
        COALESCE(l.description, '-')::TEXT,
        ('V' || l.version)::TEXT
    FROM org_log l
    WHERE l.org_id = p_org_id
    ORDER BY l.version DESC, l.log_date DESC;
END;$$;


ALTER FUNCTION public.get_recent_org_logs(p_org_id integer) OWNER TO postgres;

--
-- Name: get_report_by_code(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_report_by_code(report_code text) RETURNS TABLE(code text, name text, module text, group_name text, filter_form_code text, is_active boolean, output_file_prefix text, sp_name text, template_file_path text, parent_id text, form_name text, json_schema jsonb)
    LANGUAGE sql STABLE
    AS $$
  select
    r.code,
    r.name,
    rg.module,
    rg.group_name,
    r.filter_form_code,
    r.is_active,
    r.output_file_prefix,
    r.sp_name,
    r.template_file_path,
    r.parent_id,
    f.name as form_name,
    f.json_schema
  from
    report_definition r
  left join
    report_group rg on r.parent_id = rg.id
  left join
    form_definition f on r.filter_form_code = f.code
  where
    r.code = report_code;
$$;


ALTER FUNCTION public.get_report_by_code(report_code text) OWNER TO postgres;

--
-- Name: get_role_permission(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_role_permission(p_role_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    SELECT jsonb_build_object(
        'role_id', r.id,
        'role_name', r.name,
        'feature', jsonb_agg(
            jsonb_build_object(
                'feature_id', f.id,
                'feature_name', f.name,
                'action', (
                    SELECT jsonb_agg(
                        jsonb_build_object(
                            'id', rp.id,
                            'action_id', a.id,
                            'action_name', a.name,
                            'action_code', a.code
                        )
                    )
                    FROM role_permission rp2
                    JOIN actions a ON a.id = rp2.action_id
                    WHERE rp2.role_id = r.id AND rp2.feature_id = f.id
                )
            )
        )
    )
    INTO result
    FROM roles r
    LEFT JOIN role_permission rp ON rp.role_id = r.id
    LEFT JOIN features f ON f.id = rp.feature_id
    WHERE r.id = p_role_id
    GROUP BY r.id, r.name;

    RETURN result;
END;
$$;


ALTER FUNCTION public.get_role_permission(p_role_id integer) OWNER TO postgres;

--
-- Name: get_role_permission_json(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_role_permission_json(p_role_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    SELECT jsonb_build_object(
        'role_id', r.id,
        'role_name', r.name,
        'feature', jsonb_agg(
            jsonb_build_object(
                'feature_id', f.id,
                'feature_name', f.name,
                'action', (
                    SELECT jsonb_agg(
                        jsonb_build_object(
                            'id', rp.id,
                            'action_id', a.id,
                            'action_name', a.name,
                            'action_code', a.code
                        )
                    )
                    FROM role_permission rp2
                    JOIN actions a ON a.id = rp2.action_id
                    WHERE rp2.role_id = r.id AND rp2.feature_id = f.id
                )
            )
        )
    )
    INTO result
    FROM roles r
    LEFT JOIN role_permission rp ON rp.role_id = r.id
    LEFT JOIN features f ON f.id = rp.feature_id
    WHERE r.id = p_role_id
    GROUP BY r.id, r.name;

    RETURN result;
END;
$$;


ALTER FUNCTION public.get_role_permission_json(p_role_id integer) OWNER TO postgres;

--
-- Name: get_staff_allocation_by_org(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_staff_allocation_by_org(p_org_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_allocation INTEGER;
BEGIN
    SELECT COALESCE(SUM(staff_allocation), 0)
    INTO total_allocation
    FROM job_title_organizations
    WHERE org_id = p_org_id
    AND is_active = TRUE;

    RETURN total_allocation;
END;
$$;


ALTER FUNCTION public.get_staff_allocation_by_org(p_org_id integer) OWNER TO postgres;

--
-- Name: get_total_employees(integer, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_total_employees(p_org_id integer, p_emp_status text[] DEFAULT ARRAY['trial'::text, 'waiting'::text, 'active'::text]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    descendant_ids INT[];
    total_active_employees INTEGER;
BEGIN

    -- Lấy danh sách ID của các đơn vị con
    descendant_ids := organization_get_childs(p_org_id);
    
    -- Đếm tổng số nhân viên với status được chỉ định trong tất cả các đơn vị có ID trong danh sách
    SELECT COUNT(*)
    INTO total_active_employees
    FROM employee_list_view elv
    WHERE elv.organization_id = ANY(ARRAY[p_org_id] || descendant_ids)
    AND elv.status = ANY(p_emp_status);
    
    -- Trả về kết quả
    RETURN total_active_employees;
END;
$$;


ALTER FUNCTION public.get_total_employees(p_org_id integer, p_emp_status text[]) OWNER TO postgres;

--
-- Name: get_total_staff_allocation(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_total_staff_allocation(p_org_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
    descendant_ids INT[];
    total_allocation INTEGER;
BEGIN
    -- Lấy danh sách ID của các đơn vị con
    descendant_ids := organization_get_childs(p_org_id);

        
    -- Tính tổng định biên cho tất cả các ID trong danh sách
    SELECT COALESCE(SUM(staff_allocation), 0)
    INTO total_allocation
    FROM job_title_organizations
    WHERE org_id = ANY(ARRAY[p_org_id] || descendant_ids)
    AND is_active = TRUE;
    
    -- Trả về kết quả
    RETURN total_allocation;
END;$$;


ALTER FUNCTION public.get_total_staff_allocation(p_org_id integer) OWNER TO postgres;

--
-- Name: get_user_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_role() RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    tenant_schema TEXT;
    v_user_id UUID := current_setting('request.jwt.claims', true)::jsonb->>'sub';
BEGIN
    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    PERFORM set_config('search_path', tenant_schema, true);

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = v_user_id) THEN
        RAISE NOTICE 'User không tồn tại!';
        RETURN jsonb_build_object('error', 'User not found');
    END IF;

    -- Lấy thông tin người dùng và vai trò kèm theo cây tính năng có gắn quyền
    SELECT jsonb_build_object(
        'id', u.id,
        'name', u.name,
        'email', u.email,
        'preferred_username', u.preferred_username,
        'roles', jsonb_agg(
            jsonb_build_object(
                'role_id', r.id,
                'role_code', r.code,
                'role_name', r.name,
                'features', (
                    SELECT feature_build_tree_with_permissions(r.id)
                )
            )
        )
    )
    INTO result
    FROM users u
    LEFT JOIN user_role ur ON u.id = ur.user_id
    LEFT JOIN roles r ON r.id = ur.role_id
    WHERE u.id = v_user_id
    GROUP BY u.id, u.name, u.email, u.preferred_username;

    RETURN result;
END;
$$;


ALTER FUNCTION public.get_user_role() OWNER TO postgres;

--
-- Name: get_work_history(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_work_history(p_emp_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    PERFORM set_config('search_path', tenant_schema, true);
    
    SELECT jsonb_agg(work_item) INTO result
    FROM (
        -- Công việc hiện tại từ bảng employees
        SELECT to_jsonb(current_work) AS work_item
        FROM (
            SELECT
                NULL::INT AS id,
                e.id AS emp_id,
                e.job_title_id,
                e.organization_id,
                e.decision_no,
                e.decision_signer,
                e.decision_sign_date,
                e.start_date_change AS start_date,
                e.end_date_change AS end_date,
                e.work_note AS reason,
                e.note,
                l.name AS work_place,
                o.name AS organization_name,
                jt.name AS job_title_name,
                jsonb_build_object('name', jt.name) AS job_titles,
                jsonb_build_object(
                    'name', o.name,
                    'locations', jsonb_build_object(
                        'work_place_name', ol.name,
                        'work_place_address', ol.address
                    )
                ) AS organizations,
                jsonb_build_object('name', (SELECT name FROM enum_lookup WHERE value = e.job_change_type)) AS change_type,
                CASE
                    WHEN e.start_date_change IS NULL OR e.end_date_change IS NULL THEN NULL
                    ELSE (
                        EXTRACT(YEAR FROM age(e.end_date_change, e.start_date_change)) * 12 +
                        EXTRACT(MONTH FROM age(e.end_date_change, e.start_date_change)) +
                        CASE
                            WHEN EXTRACT(DAY FROM age(e.end_date_change, e.start_date_change)) > 0 THEN 1
                            ELSE 0
                        END
                    )::int
                END AS total_month
            FROM employees e
            LEFT JOIN job_titles jt ON e.job_title_id = jt.id
            LEFT JOIN organizations o ON e.organization_id = o.id
            LEFT JOIN locations l ON e.work_location_id = l.id
            LEFT JOIN locations ol ON o.location_id = ol.id
            WHERE e.id = p_emp_id
        ) current_work

        UNION ALL

        -- Lịch sử làm việc từ bảng work_histories
        SELECT to_jsonb(history_work) AS work_item
        FROM (
            SELECT
                w.id,
                w.emp_id,
                w.job_title_id,
                w.organization_id,
                w.decision_no,
                w.decision_signer,
                w.decision_sign_date,
                w.start_date,
                w.end_date,
                w.reason,
                w.note,
                w.work_place,
                o.name AS organization_name,
                jt.name AS job_title_name,
                jsonb_build_object('name', jt.name) AS job_titles,
                jsonb_build_object(
                    'name', o.name,
                    'locations', jsonb_build_object(
                        'work_place_name', l.name,
                        'work_place_address', l.address
                    )
                ) AS organizations,
                jsonb_build_object('name', el.name) AS change_type,
                CASE
                    WHEN w.start_date IS NULL OR w.end_date IS NULL THEN NULL
                    ELSE (
                        EXTRACT(YEAR FROM age(w.end_date, w.start_date)) * 12 +
                        EXTRACT(MONTH FROM age(w.end_date, w.start_date)) +
                        CASE
                            WHEN EXTRACT(DAY FROM age(w.end_date, w.start_date)) > 0 THEN 1
                            ELSE 0
                        END
                    )::int
                END AS total_month
            FROM work_histories w
            LEFT JOIN job_titles jt ON w.job_title_id = jt.id
            LEFT JOIN organizations o ON w.organization_id = o.id
            LEFT JOIN enum_lookup el ON w.change_type_id = el.id
            LEFT JOIN locations l ON o.location_id = l.id
            WHERE w.emp_id = p_emp_id
            ORDER BY w.start_date DESC
        ) history_work
    ) AS combined_work;

    RETURN result;
END;
$$;


ALTER FUNCTION public.get_work_history(p_emp_id integer) OWNER TO postgres;

--
-- Name: history_employees(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.history_employees(p_emp_id integer, p_action character varying) RETURNS TABLE(status text, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
  v_enum_info JSONB;
  -- v_union_records JSONB;
  v_degree_info JSONB;
  v_certif_info JSONB;
  v_rewards_discipline JSONB;
  v_external_experiences JSONB;
  v_family_dependents JSONB;
  v_internal_working JSONB;
  tenant_schema TEXT;
BEGIN
  RAISE NOTICE 'Bắt đầu history_employees lúc: %, employee id: %, action: %', clock_timestamp(), p_emp_id, p_action;

  -- -- Lấy schema từ JWT
  -- tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  -- RAISE NOTICE 'Bước 1: Đã lấy schema từ JWT: %', tenant_schema;

  -- -- Thiết lập search_path theo schema
  -- PERFORM set_config('search_path', tenant_schema, true);
  -- RAISE NOTICE 'Bước 2: Đã set search_path = %', tenant_schema;

  -- Kiểm tra nhân viên có tồn tại hay không
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RAISE NOTICE 'Bước 3: Không tìm thấy nhân viên có ID %', p_emp_id;
    RETURN QUERY SELECT 'ERROR', 'Không tìm thấy nhân viên với ID ' || p_emp_id;
    RETURN;
  END IF;
  RAISE NOTICE 'Bước 3: Nhân viên tồn tại, tiếp tục xử lý';

  -- ghi lại thông tin các trường như dân tộc, tôn giáo, nghề nghiệp, nơi cấp cccd, chứng chỉ tiếng anh, tin học
  RAISE NOTICE '🔍 Bước 4: Lấy thông tin các trường enum_lookup';
  SELECT json_build_object(
    'religion', json_build_object('id', e.religion_id, 'value', rl.value, 'name', rl.name),
    'ethnicity', json_build_object('id', e.ethnicity_id, 'value', en.value, 'name', en.name),
    'occupation', json_build_object('id', e.occupation_id, 'value', oc.value, 'name', oc.name),
    'place_issue', json_build_object('id', e.place_issue_id, 'value', pi.value, 'name', pi.name),
    -- 'old_place_issue', json_build_object('id', e.old_place_issue_id, 'value', opi.value, 'name', opi.name),
    'en_cert', json_build_object( 'id', e.en_cert_id, 'value', enc.value, 'name', enc.name),
    'it_cert', json_build_object('id', e.it_cert_id, 'value', itc.value, 'name', itc.name)
  )
  INTO v_enum_info
  FROM employees e
  left join enum_lookup rl on rl.id = e.religion_id
  left join enum_lookup en on en.id = e.ethnicity_id
  left join enum_lookup oc on oc.id = e.occupation_id
  left join enum_lookup pi on pi.id = e.place_issue_id
  -- left join enum_lookup opi on opi.id = e.old_place_issue_id
  left join enum_lookup enc on enc.id = e.en_cert_id
  left join enum_lookup itc on itc.id = e.it_cert_id
  WHERE e.id = p_emp_id;
  RAISE NOTICE 'Bước 4: Lấy enum_info xong';

  -- RAISE NOTICE 'Bước 5: Trích xuất degrees';
  -- SELECT COALESCE(json_agg(row_data), '[]') INTO v_union_records
  -- FROM (
  --   SELECT 
  --     u.id, u.emp_id, u.start_date, u.fee_date, u.decision_no, u.decision_date, 
  --     u.appointment_no, u.position, u.organization_name, u.status as status_union, u.activity 
  --   FROM union_records u
  --   WHERE emp_id = p_emp_id
  -- ) AS row_data;
  -- RAISE NOTICE 'Bước 5: Trích xuất degrees xong';


  SELECT COALESCE(json_agg(row_data), '[]') INTO v_degree_info
  FROM (
    SELECT id, emp_id, is_main, type, degree_no, academic, institution, 
      classification, faculty, major, education_mode, start_date, end_date,
      graduation_year, training_location, note 
    FROM degrees
    WHERE emp_id = p_emp_id
  ) AS row_data;
  RAISE NOTICE 'Bước 6: Trích xuất degrees xong, bắt đầu trích xuất certificates';

  SELECT COALESCE(json_agg(row_data), '[]') INTO v_certif_info
  FROM(
    SELECT 
      ct.id, ct.emp_id, ct.type_id, el.name as certif_type_name, ct.cert_no, ct.name, 
      ct.issued_by, ct.date_issue, ct.expired_date, ct.note
    FROM certificates ct
    LEFT JOIN enum_lookup el on ct.type_id = el.id
    WHERE emp_id = p_emp_id
  ) AS row_data; 
  RAISE NOTICE 'Bước 7: Trích xuất certificates xong, bắt đầu trích xuất rewards/discipline';

  SELECT COALESCE(json_agg(row_data), '[]') INTO v_rewards_discipline
  FROM(
    SELECT 
      rd.id, emp_id, rd.decision_no, rd.type_reward_id, el.name as decision_authority_name, 
      rd.issuer, rd.issuer_position,  rd.decision_date, rd.start_date, rd.end_date, rd.note, rd.type, rd.form,
      rd.decision_authority_name, rd.reason
    FROM reward_disciplinary rd
    LEFT JOIN enum_lookup el on el.id = rd.type_reward_id
    WHERE emp_id = p_emp_id
  ) AS row_data;
  RAISE NOTICE 'Bước 8: Trích xuất rewards_discipline xong, bắt đầu trích xuất family_dependents';

  SELECT COALESCE(json_agg(row_data), '[]') INTO v_family_dependents
  FROM(
    SELECT 
      fd.id, fd.emp_id, fd.full_name, fd.gender, fd.dob, fd.address, fd.phone,
      fd.email, fd.identity_no, fd.identity_type, fd.tax_no, fd.is_tax_dependent,
      fd.occupation, fd.workplace, fd.before_1975, fd.after_1975, fd.note,
      fd.is_alive, fd.relationship_type_id, rt.name as relationship_type_name, fd.relative_emp_id, 
      fd.is_dependent, fd.reason, fd.deduction_start_date, fd.deduction_end_date
    FROM family_dependents fd
    LEFT JOIN relationship_types rt on rt.id = fd.relationship_type_id
    WHERE emp_id = p_emp_id
  ) AS row_data;
  RAISE NOTICE 'Bước 9: Trích xuất family_dependents xong, bắt đầu trích xuất external_experiences';

  SELECT COALESCE(json_agg(row_data), '[]') INTO v_external_experiences
  FROM (
    SELECT
      id, emp_id, position, company_name, address, start_date, end_date,
      start_salary, current_salary, phone, contact, contact_position,
      main_duty, reason_leave, note
    FROM external_experiences
    WHERE emp_id = p_emp_id
  ) AS row_data;
  RAISE NOTICE 'Bước 10: Trích xuất external_experiences xong, bắt đầu trích xuất internal_working';

  SELECT COALESCE(json_agg(row_data), '[]') INTO v_internal_working
  FROM (
      -- Current work from employees table
      SELECT
          NULL::INT AS id,
          e.id AS emp_id,
          e.job_title_id,
          jt.name AS job_title_name,         
          e.organization_id,
          o.name AS organization_name,  
          l.name AS work_place,
          COALESCE(
            (SELECT name FROM enum_lookup WHERE value = e.job_change_type),
            'Không xác định'
          ) AS change_type,
          e.decision_no,
          e.decision_signer,
          e.decision_sign_date,
          e.start_date_change AS start_date,
          e.date_resign AS end_date,
          e.work_note AS reason,
          e.note
      FROM employees e
      LEFT JOIN job_titles jt ON e.job_title_id = jt.id
      LEFT JOIN organizations o ON e.organization_id = o.id
      LEFT JOIN locations l ON e.work_location_id = l.id
      LEFT JOIN locations ol ON o.location_id = ol.id
      WHERE e.id = p_emp_id

      UNION ALL

      -- Historical work from work_histories table
      SELECT
          wk.id,
          wk.emp_id,
          wk.job_title_id,
          jt.name AS job_title_name,
          wk.organization_id,
          og.name AS organization_name,
          wk.work_place,
          el.name AS change_type,
          wk.decision_no,
          wk.decision_signer,
          wk.decision_sign_date,
          wk.start_date,
          wk.end_date,
          wk.reason,
          wk.note
      FROM work_histories wk
      LEFT JOIN job_titles jt ON jt.id = wk.job_title_id
      LEFT JOIN organizations og ON og.id = wk.organization_id
      LEFT JOIN enum_lookup el ON el.id = wk.change_type_id
      WHERE wk.emp_id = p_emp_id
  ) AS row_data;


  RAISE NOTICE 'Bước 11: Trích xuất internal_working xong, bắt đầu insert log lịch sử nhân sự';

  INSERT INTO employee_histories (
  emp_id, action, log_date, emp_code, emp_code_old, nationality_id, enum_info,
  last_name, middle_name, first_name, full_name, gender, dob, temporary_address, temporary_district_id, temporary_district_name,
  hometown_provinces_id, hometown_provinces_name, permanent_address, permanent_district_id, permanent_district_name, email_internal, email_external, phone,
  secondary_phone, home_phone, company_phone, marital_status, education_level, profile_introduced,
  job_title_id, organization_id, work_location_id, work_location_address, avatar, note, old_identity_no, old_date_issue,
  old_place_issue_id, identity_type, identity_no, date_issue, date_identity_expiry, place_issue_id,
  date_join, date_probation_start, date_official_start, date_resign, last_work_date, blood_group,
  blood_pressure, height_cm, weight_kg, job_change_type, manager_id, manager_name, decision_no, decision_signer,
  decision_sign_date, start_date_change, end_date_change, work_note, tax_no, cif_code,
  bank_account_no, bank_name, is_social_insurance, is_unemployment_insurance, is_life_insurance,
  party_start_date, party_official_date, union_youth_start_date,military_start_date, military_end_date,
  military_highest_rank, is_old_regime, is_wounded_soldier, en_cert_id, it_cert_id,
  degree_type, academic, institution, faculty, major, graduation_year, degree_info,
  certif_info, rewards_discipline, external_work, internal_working, family_relationships, employee_type,
  union_start_date, union_fee_date, union_decision_no, union_decision_date, union_position, union_organization_name, union_status, union_activity, organization_name, job_title_name, nationality_name
  ) SELECT e.id, p_action, NOW(), e.emp_code, e.emp_code_old, e.nationality_id, v_enum_info, e.last_name, e.middle_name, 
  e.first_name, e.full_name, e.gender, e.dob, e.temporary_address, e.temporary_district_id, dtt.name,
  e.hometown_provinces_id, htp.name, e.permanent_address, e.permanent_district_id, dtp.name, e.email_internal, e.email_external, e.phone,
  e.secondary_phone, e.home_phone, e.company_phone, e.marital_status, e.education_level, e.profile_introduced,
  e.job_title_id, e.organization_id, e.work_location_id, wkl.address, e.avatar, e.note, e.old_identity_no, e.old_date_issue,
  e.old_place_issue_id, e.identity_type, e.identity_no, e.date_issue, e.date_identity_expiry, e.place_issue_id,
  e.date_join, e.date_probation_start, e.date_official_start, e.date_resign, e.last_work_date, e.blood_group,
  e.blood_pressure, e.height_cm, e.weight_kg, e.job_change_type, e.manager_id, mng.full_name, e.decision_no, e.decision_signer,
  e.decision_sign_date, e.start_date_change, e.end_date_change, e.work_note, e.tax_no, e.cif_code,
  e.bank_account_no, e.bank_name, e.is_social_insurance, e.is_unemployment_insurance, e.is_life_insurance,
  e.party_start_date, e.party_official_date, e.union_youth_start_date, e.military_start_date, e.military_end_date,
  e.military_highest_rank, e.is_old_regime, e.is_wounded_soldier, e.en_cert_id, e.it_cert_id,
  e.degree_type, e.academic, e.institution, e.faculty, e.major, e.graduation_year, v_degree_info,
  v_certif_info, v_rewards_discipline, v_external_experiences, v_internal_working, v_family_dependents, e.employee_type, 
  e.union_start_date, e.union_fee_date, e.union_decision_no, e.union_decision_date, e.union_position, e.union_organization_name,
  e.union_status, e.union_activity, org.name, jt.name, ntn.name
  FROM employees e
  left join provinces htp on htp.id = e.hometown_provinces_id
  left join districts dtt on dtt.id = e.temporary_district_id 
  left join districts dtp on dtp.id = e.permanent_district_id
  left join locations wkl on wkl.id = e.work_location_id
  left join employees mng on mng.id = e.manager_id
  left join organizations org on org.id = e.organization_id
  left join job_titles jt on  jt.id = e.job_title_id
  left join national ntn on ntn.id =e.nationality_id

   WHERE e.id = p_emp_id;
  RAISE NOTICE 'Bước 12: Ghi log employee_histories thành công cho nhân viên ID %', p_emp_id;

  RAISE NOTICE 'Kết thúc history_employees lúc: %, employee id: %, action: %', clock_timestamp(), p_emp_id, p_action;
  RETURN QUERY SELECT 'SUCCESS', 'Ghi log lịch sử thành công';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Bắt được lỗi khi ghi log lịch sử: %', SQLERRM;
       RETURN QUERY SELECT 'ERROR', 'Lỗi ghi log: ' || SQLERRM ;
END;$$;


ALTER FUNCTION public.history_employees(p_emp_id integer, p_action character varying) OWNER TO postgres;

--
-- Name: history_infor_emp(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.history_infor_emp(log_id_new integer, log_id_old integer) RETURNS TABLE(action text, action_date timestamp without time zone, modified_by text, field_name text, old_value text, new_value text)
    LANGUAGE plpgsql
    AS $$
DECLARE 
    r_new RECORD;
    r_old RECORD;
    old_enum JSONB;
    new_enum JSONB;
    tenant_schema TEXT;
BEGIN

    -- Lấy dữ liệu từ 2 log
    SELECT * INTO r_new FROM employee_histories WHERE id = log_id_new;
    SELECT * INTO r_old FROM employee_histories WHERE id = log_id_old;

    old_enum := r_old.enum_info;
    new_enum := r_new.enum_info;

    -- 1. Trả các field thường
    RETURN QUERY
    SELECT 
        r_new.action::TEXT,
        r_new.log_date::TIMESTAMP,
        r_new.modified_by::TEXT,
        new_data.key,
        old_data.value,
        new_data.value
    FROM 
        jsonb_each_text(to_jsonb(r_old)) AS old_data
    JOIN 
        jsonb_each_text(to_jsonb(r_new)) AS new_data
        ON old_data.key = new_data.key
    WHERE 
        old_data.value IS DISTINCT FROM new_data.value
        AND new_data.key NOT IN (
            'id', 'action', 'log_date', 'created_at', 'modified_at', 'enum_info'
        );

    -- 2. Trả các field enum trong enum_info
    RETURN QUERY
    SELECT 
        r_new.action::TEXT,
        r_new.log_date::TIMESTAMP,
        r_new.modified_by::TEXT,
        enum_changes.field_name,
        enum_changes.old_value,
        enum_changes.new_value
    FROM (
        VALUES
            ('religion',
                jsonb_extract_path_text(old_enum, 'religion', 'name'),
                jsonb_extract_path_text(new_enum, 'religion', 'name')
            ),
            ('ethnicity',
                jsonb_extract_path_text(old_enum, 'ethnicity', 'name'),
                jsonb_extract_path_text(new_enum, 'ethnicity', 'name')
            ),
            ('occupation',
                jsonb_extract_path_text(old_enum, 'occupation', 'name'),
                jsonb_extract_path_text(new_enum, 'occupation', 'name')
            ),
            ('place_issue',
                jsonb_extract_path_text(old_enum, 'place_issue', 'name'),
                jsonb_extract_path_text(new_enum, 'place_issue', 'name')
            ),
            ('old_place_issue',
                jsonb_extract_path_text(old_enum, 'old_place_issue', 'name'),
                jsonb_extract_path_text(new_enum, 'old_place_issue', 'name')
            ),
            ('en_cert',
                jsonb_extract_path_text(old_enum, 'en_cert', 'name'),
                jsonb_extract_path_text(new_enum, 'en_cert', 'name')
            ),
            ('it_cert',
                jsonb_extract_path_text(old_enum, 'it_cert', 'name'),
                jsonb_extract_path_text(new_enum, 'it_cert', 'name')
            )
    ) AS enum_changes(field_name, old_value, new_value)
    WHERE enum_changes.old_value IS DISTINCT FROM enum_changes.new_value;

END;
$$;


ALTER FUNCTION public.history_infor_emp(log_id_new integer, log_id_old integer) OWNER TO postgres;

--
-- Name: history_org_log(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.history_org_log(org_id_param integer) RETURNS TABLE(change_type text, action_date timestamp without time zone, action_by text, old_info text, new_info text, log_effective_date text, log_description text, log_version integer)
    LANGUAGE plpgsql
    AS $$
DECLARE 
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    RETURN QUERY
    WITH log_with_row AS (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY org_id ORDER BY version ASC) AS row_num,
            ol.id AS log_id,
            ol.org_id,
            ol.action::TEXT AS change_type,  
            ol.log_date,
            COALESCE(ol.name, '')::TEXT AS name,
            COALESCE(ol.en_name, '')::TEXT AS en_name,
            ol.category_id,
            ol.parent_org_id,
            ol.location_id,
            COALESCE(ol.phone, '')::TEXT AS phone,
            COALESCE(ol.email, '')::TEXT AS email,
            COALESCE(ol.effective_date::TEXT, '') AS log_effective_date,
            COALESCE(ol.expired_date::TEXT, '') AS expired_date,
            ol.cost_centers_id,
            ol.is_active,
            COALESCE(ol.approve_struct, '')::TEXT AS approve_struct,
            ol.version,
            COALESCE(ol.decision_no, '')::TEXT AS decision_no,
            COALESCE(ol.decision_date::TEXT, '') AS decision_date,
            ol.general_manager_id,
            ol.direct_manager_id,
            COALESCE(ol.description, '')::TEXT AS log_description,
            COALESCE(ol.created_by, '')::TEXT AS log_action_by,
            (
                SELECT COALESCE(STRING_AGG(a.file_name, ', '), '')
                FROM org_log_attachment ola
                JOIN attachments a ON ola.attachment_id = a.id
                WHERE ola.log_id = ol.id 
            ) AS attachments
        FROM org_log ol
        WHERE ol.org_id = org_id_param
        ORDER BY ol.version ASC
    )
    SELECT distinct
        CASE 
            WHEN l1.change_type = 'UPDATE' THEN 'Cập nhật'
            WHEN l1.change_type = 'CREATE' THEN 'Tạo mới'
            WHEN l1.change_type = 'DELETE' THEN 'Xóa'
            WHEN l1.change_type = 'DISSOLVE' THEN 'Giải thể'
            WHEN l1.change_type = 'MERGED' THEN 'Sáp nhập'
            WHEN l1.change_type = 'UPDATE AFTER MERGER' THEN 'Cập nhật sau khi sáp nhập'
            WHEN l1.change_type = 'UPDATED PARENT' THEN 'Chuyển đơn vị con khi sáp nhập'
            WHEN l1.change_type = 'SPLIT PARENT' THEN 'Chuyển đơn vị con khi chia tách'
            WHEN l1.change_type = 'UPDATE AFTER SPLIT' THEN 'Cập nhật sau khi chia tách'
            ELSE l1.change_type 
        END AS change_type,
        l1.log_date AS action_date, 
        l1.log_action_by AS action_by,
        CASE 
        WHEN l1.row_num = 1 THEN '-'
        ELSE changes.old_info
    END AS old_info,
    CASE 
        WHEN l1.row_num = 1 THEN '-'
        ELSE changes.new_info
    END AS new_info,
        l1.log_effective_date AS log_effective_date,  
        l1.log_description AS log_description,  
        l1.version AS log_version  
    FROM log_with_row l1
    LEFT JOIN log_with_row l2 ON l1.row_num = l2.row_num + 1
    CROSS JOIN LATERAL UNNEST(
    ARRAY[
        CASE WHEN COALESCE(l1.name, '') <> COALESCE(l2.name, '') THEN FORMAT('Tên đơn vị: "%s"', l2.name) END,
        CASE WHEN COALESCE(l1.en_name, '') <> COALESCE(l2.en_name, '') THEN FORMAT('Tên tiếng Anh đơn vị: "%s"', l2.en_name) END,
        CASE WHEN l1.category_id <> l2.category_id THEN FORMAT('Loại hình đơn vị: "%s"', 
            COALESCE((SELECT name FROM enum_lookup WHERE id = l2.category_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN l1.parent_org_id <> l2.parent_org_id THEN FORMAT('Đơn vị cấp trên: "%s"', 
            COALESCE((SELECT name FROM organizations WHERE id = l2.parent_org_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN l1.location_id <> l2.location_id THEN FORMAT('Địa chỉ: "%s"', 
            COALESCE((SELECT name FROM locations WHERE id = l2.location_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN COALESCE(l1.phone, '') <> COALESCE(l2.phone, '') THEN FORMAT('Số điện thoại: "%s"', l2.phone) END,
        CASE WHEN COALESCE(l1.email, '') <> COALESCE(l2.email, '') THEN FORMAT('Email: "%s"', l2.email) END,
        CASE WHEN l1.log_effective_date <> l2.log_effective_date THEN FORMAT('Ngày hiệu lực: "%s"', l2.log_effective_date) END,
        CASE WHEN l1.expired_date <> l2.expired_date THEN FORMAT('Ngày hết hạn: "%s"', l2.expired_date) END,
        CASE WHEN l1.cost_centers_id <> l2.cost_centers_id THEN FORMAT('Trung tâm chi phí: "%s"', 
            COALESCE((SELECT name FROM cost_centers WHERE id = l2.cost_centers_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN l1.is_active <> l2.is_active THEN FORMAT('Trạng thái hoạt động: "%s"', l2.is_active::TEXT) END,
        CASE WHEN COALESCE(l1.approve_struct, '') <> COALESCE(l2.approve_struct, '') THEN FORMAT('Cấu trúc phê duyệt: "%s"', l2.approve_struct) END,
        CASE WHEN COALESCE(l1.decision_no, '') <> COALESCE(l2.decision_no, '') THEN FORMAT('Số quyết định: "%s"', l2.decision_no) END,
        CASE WHEN COALESCE(l1.decision_date, '') <> COALESCE(l2.decision_date, '') THEN FORMAT('Ngày quyết định: "%s"', l2.decision_date) END,
        CASE WHEN COALESCE(l1.general_manager_id, 0) <> COALESCE(l2.general_manager_id, 0) THEN FORMAT('Người phụ trách chung: "%s"', 
            COALESCE((SELECT full_name FROM employees WHERE id = l2.general_manager_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN COALESCE(l1.direct_manager_id, 0) <> COALESCE(l2.direct_manager_id, 0) THEN FORMAT('Người phụ trách trực tiếp: "%s"', 
            COALESCE((SELECT full_name FROM employees WHERE id = l2.direct_manager_id LIMIT 1), 'Không xác định')) END,

      -- NEW_INFO
      CASE 
        WHEN COALESCE(l1.attachments, '') <> COALESCE(l2.attachments, '')
            AND COALESCE(l1.attachments, '') <> ''
        THEN FORMAT('-')
        WHEN COALESCE(l1.attachments, '') <> ''
            AND COALESCE(l2.attachments, '') = ''
            AND EXISTS (
                SELECT 1 FROM org_log_attachment ola
                WHERE ola.log_id = l1.log_id
            )
        THEN FORMAT('-')
      END

    ],
    ARRAY[
        CASE WHEN COALESCE(l1.name, '') <> COALESCE(l2.name, '') THEN FORMAT('Thay đổi thành: "%s"', l1.name) END,
        CASE WHEN COALESCE(l1.en_name, '') <> COALESCE(l2.en_name, '') THEN FORMAT('Thay đổi thành: "%s"', l1.en_name) END,
        CASE WHEN l1.category_id <> l2.category_id THEN FORMAT('Thay đổi thành loại hình: "%s"', 
            COALESCE((SELECT name FROM enum_lookup WHERE id = l1.category_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN l1.parent_org_id <> l2.parent_org_id THEN FORMAT('Thay đổi đơn vị cấp trên thành: "%s"', 
            COALESCE((SELECT name FROM organizations WHERE id = l1.parent_org_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN l1.location_id <> l2.location_id THEN FORMAT('Thay đổi địa chỉ thành: "%s"', 
            COALESCE((SELECT name FROM locations WHERE id = l1.location_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN COALESCE(l1.phone, '') <> COALESCE(l2.phone, '') THEN FORMAT('Thay đổi thành: "%s"', l1.phone) END,
        CASE WHEN COALESCE(l1.email, '') <> COALESCE(l2.email, '') THEN FORMAT('Thay đổi thành: "%s"', l1.email) END,
        CASE WHEN l1.log_effective_date <> l2.log_effective_date THEN FORMAT('Thay đổi thành: "%s"', l1.log_effective_date) END,
        CASE WHEN l1.expired_date <> l2.expired_date THEN FORMAT('Thay đổi thành: "%s"', l1.expired_date) END,
        CASE WHEN l1.cost_centers_id <> l2.cost_centers_id THEN FORMAT('Thay đổi trung tâm chi phí thành: "%s"', 
            COALESCE((SELECT name FROM cost_centers WHERE id = l1.cost_centers_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN l1.is_active <> l2.is_active THEN FORMAT('Thay đổi thành: "%s"', l1.is_active::TEXT) END,
        CASE WHEN COALESCE(l1.approve_struct, '') <> COALESCE(l2.approve_struct, '') THEN FORMAT('Thay đổi cấu trúc phê duyệt thành: "%s"', l1.approve_struct) END,
        CASE WHEN COALESCE(l1.decision_no, '') <> COALESCE(l2.decision_no, '') THEN FORMAT('Thay đổi số quyết định thành: "%s"', l1.decision_no) END,
        CASE WHEN COALESCE(l1.decision_date, '') <> COALESCE(l2.decision_date, '') THEN FORMAT('Thay đổi ngày quyết định thành: "%s"', l1.decision_date) END,
        CASE WHEN COALESCE(l1.general_manager_id, 0) <> COALESCE(l2.general_manager_id, 0) THEN FORMAT('Người phụ trách chung: "%s"', 
            COALESCE((SELECT full_name FROM employees WHERE id = l1.general_manager_id LIMIT 1), 'Không xác định')) END,
        CASE WHEN COALESCE(l1.direct_manager_id, 0) <> COALESCE(l2.direct_manager_id, 0) THEN FORMAT('Người phụ trách trực tiếp: "%s"', 
            COALESCE((SELECT full_name FROM employees WHERE id = l1.direct_manager_id LIMIT 1), 'Không xác định')) END,
        -- NEW_INFO
        CASE 
          WHEN COALESCE(l1.attachments, '') <> COALESCE(l2.attachments, '')
              AND COALESCE(l1.attachments, '') <> ''
          THEN FORMAT('Văn bản mới: "%s"', l1.attachments)
          WHEN COALESCE(l1.attachments, '') <> ''
              AND COALESCE(l2.attachments, '') = ''
              AND EXISTS (
                  SELECT 1 FROM org_log_attachment ola
                  WHERE ola.log_id = l1.log_id
              )
          THEN FORMAT('Văn bản mới: "%s"', l1.attachments)
        END
    ]
    ) AS changes(old_info, new_info)
    WHERE changes.old_info IS NOT NULL
    ORDER BY l1.version DESC;


END;
$$;


ALTER FUNCTION public.history_org_log(org_id_param integer) OWNER TO postgres;

--
-- Name: job_grade_add(integer, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.job_grade_add(p_level integer, p_code character varying, p_name character varying, p_en_name character varying DEFAULT NULL::character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_job_grade_id INT;
    v_error_code TEXT;
    v_error_message TEXT;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Kiểm tra dữ liệu đầu vào
    

    -- Thêm mới cấp bậc chức danh vào bảng job_grades
    INSERT INTO job_grades (
        level, code, name, en_name
    ) VALUES (
        p_level, p_code, p_name, p_en_name
    )
    RETURNING id INTO v_job_grade_id;

    -- Trả về kết quả thành công
    RETURN json_build_object(
        'status', 'SUCCESS',
        'message', 'Thêm mới cấp bậc thành công',
        'job_grade_id', v_job_grade_id
    );

EXCEPTION
    -- Bắt lỗi CHECK CONSTRAINT (vi phạm ràng buộc level >= 0)
    WHEN SQLSTATE '23514' THEN
        RETURN json_build_object(
            'status', 'FAIL',
            'error_code', '23514',
            'message', 'Lỗi vi phạm ràng buộc: Level phải >= 0'
        );

    -- Nếu dữ liệu trùng `level` + `name`
    WHEN unique_violation THEN
        RETURN json_build_object(
            'status', 'FAIL',
            'error_code', '23505',
            'message', FORMAT('Ngạch %s với bậc %s đã tồn tại', p_name, p_level)
        );

    -- Nếu `code` bị trùng hoặc lỗi khác
    WHEN OTHERS THEN
        v_error_code := SQLSTATE;
        v_error_message := SQLERRM;
        RETURN json_build_object(
            'status', 'FAIL',
            'error_code', v_error_code,
            'message', v_error_message
        );
END;
$$;


ALTER FUNCTION public.job_grade_add(p_level integer, p_code character varying, p_name character varying, p_en_name character varying) OWNER TO postgres;

--
-- Name: job_group_add(character varying, character varying, character varying, boolean, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.job_group_add(p_code character varying, p_name character varying, p_en_name character varying, p_is_active boolean DEFAULT true, p_sort_order integer DEFAULT 0, p_description text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_job_group_id INT;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Log bắt đầu thêm mới
    RAISE LOG 'Starting add_job_group: code=%s, name=%s', p_code, p_name;

    -- Gọi hàm validate để kiểm tra dữ liệu đầu vào
    PERFORM validate_create_job_group(p_code, p_name);

    -- Chèn dữ liệu vào bảng job_groups
    INSERT INTO job_groups (
        code, name, en_name, is_active, sort_order, description
    ) VALUES (
        p_code, p_name, p_en_name, p_is_active, p_sort_order, p_description
    ) RETURNING id INTO v_job_group_id;

    -- Log thêm mới thành công
    RAISE LOG 'Successfully added job group: id=%s, code=%s', v_job_group_id, p_code;

    -- Trả về JSON response thành công
    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'message', 'Job group added successfully',
        'job_group_id', v_job_group_id
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Log lỗi
        RAISE LOG 'Error adding job group: %', SQLERRM;

        -- Trả về JSON response lỗi
        RETURN jsonb_build_object(
            'status', 'FAIL',
            'message', format('Error adding job group: %s', SQLERRM)
        );
END;
$$;


ALTER FUNCTION public.job_group_add(p_code character varying, p_name character varying, p_en_name character varying, p_is_active boolean, p_sort_order integer, p_description text) OWNER TO postgres;

--
-- Name: job_title_add(character varying, character varying, integer, character varying, boolean, integer, integer, integer, text, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.job_title_add(code character varying, name character varying, group_id integer, en_name character varying DEFAULT NULL::character varying, is_management boolean DEFAULT false, grade_id integer DEFAULT NULL::integer, parent_id integer DEFAULT NULL::integer, cost_center_id integer DEFAULT NULL::integer, description text DEFAULT NULL::text, foreign_name character varying DEFAULT NULL::character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_job_title_id INT;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Log bắt đầu thêm mới
    RAISE LOG 'Bắt đầu thêm mới chức danh công việc: mã=%s, tên=%s, nhóm=%s', code, name, group_id;

    -- Gọi hàm kiểm tra dữ liệu đầu vào
    PERFORM validate_create_job_title(code, name, group_id, grade_id);

    -- Chèn dữ liệu vào bảng job_titles
    INSERT INTO job_titles (
        code, name, en_name, group_id, is_management, grade_id, parent_id, cost_center_id, description, foreign_name
    ) VALUES (
        code, name, en_name, group_id, is_management, grade_id, parent_id, cost_center_id, description, foreign_name
    ) RETURNING id INTO v_job_title_id;

    -- Log thêm mới thành công
    RAISE LOG 'Thêm mới chức danh công việc thành công: id=%s, mã=%s', v_job_title_id, code;

    -- Trả về JSON phản hồi thành công
    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'message', 'Thêm mới chức danh công việc thành công',
        'job_title_id', v_job_title_id
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Log lỗi
        RAISE LOG 'Lỗi khi thêm mới chức danh công việc: %', SQLERRM;

        -- Trả về JSON phản hồi lỗi
        RETURN jsonb_build_object(
            'status', 'FAIL',
            'message', format('Lỗi khi thêm mới chức danh công việc: %s', SQLERRM)
        );
END;
$$;


ALTER FUNCTION public.job_title_add(code character varying, name character varying, group_id integer, en_name character varying, is_management boolean, grade_id integer, parent_id integer, cost_center_id integer, description text, foreign_name character varying) OWNER TO postgres;

--
-- Name: job_title_update(integer, character varying, character varying, integer, character varying, boolean, integer, integer, integer, text, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.job_title_update(p_job_title_id integer, p_code character varying, p_name character varying, p_group_id integer, p_en_name character varying, p_is_management boolean, p_grade_id integer, p_parent_id integer, p_cost_center_id integer, p_description text, p_foreign_name character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_code VARCHAR(50);
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);
    
    -- Kiểm tra hợp lệ đầu vào trước khi cập nhật
    PERFORM validate_update_job_title(p_code, p_job_title_id, p_name, p_group_id, p_grade_id);

    -- Cập nhật bảng job_titles
    UPDATE job_titles
    SET 
        name = p_name,
        code = p_code,
        en_name = p_en_name,
        group_id = p_group_id,
        is_management = p_is_management,
        grade_id = p_grade_id,
        parent_id = p_parent_id,
        cost_center_id = p_cost_center_id,
        description = p_description,
        foreign_name = p_foreign_name
    WHERE id = p_job_title_id
    RETURNING code INTO v_code;

    -- Nếu không có bản ghi nào bị ảnh hưởng, nghĩa là ID không tồn tại
    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'FAIL', 'message', 'Chức danh công việc không tồn tại');
    END IF;

    -- Trả về kết quả thành công
    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'message', 'Cập nhật chức danh công việc thành công',
        'job_title_id', p_job_title_id,
        'code', v_code
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Ghi log lỗi
        RAISE LOG 'Lỗi khi cập nhật chức danh công việc: %', SQLERRM;

        -- Trả về lỗi dưới dạng JSON
        RETURN jsonb_build_object(
            'status', 'FAIL',
            'message', format('Lỗi khi cập nhật chức danh công việc: %s', SQLERRM)
        );
END;
$$;


ALTER FUNCTION public.job_title_update(p_job_title_id integer, p_code character varying, p_name character varying, p_group_id integer, p_en_name character varying, p_is_management boolean, p_grade_id integer, p_parent_id integer, p_cost_center_id integer, p_description text, p_foreign_name character varying) OWNER TO postgres;

--
-- Name: log_audit(text, text, integer, jsonb, jsonb, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_audit(table_name text, operation text, record_id integer, old_data jsonb, new_data jsonb, reason text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE
  claims        JSONB;
  v_sub         TEXT;
  v_name        TEXT;
  v_pref_un     TEXT;
  v_email       TEXT;
  v_user_id       UUID;
  username      TEXT;
  supa_roles    TEXT[];
  realm_roles   TEXT[];
  sess_id       TEXT;
  req_id        TEXT;
  tenant_schema TEXT;
  cli_ip        TEXT;
BEGIN
  -- 1) Đọc GUC JWT claims, nếu không có thì claims := NULL
  BEGIN
    claims := current_setting('request.jwt.claims', true)::JSONB;
  EXCEPTION WHEN invalid_parameter_value THEN
    claims := NULL;
  END;

  -- 2) Nếu có claims, parse từng trường riêng lẻ
  IF claims IS NOT NULL THEN
    -- sub, name, preferred_username, email
    v_sub     := claims->>'sub';
    v_name    := claims->>'name';
    v_pref_un := claims->>'preferred_username';
    v_email   := claims->>'email';

    -- Ép kiểu sub thành UUID, nếu không hợp lệ thì propagate lỗi
    v_user_id := v_sub::UUID;

    -- username ưu tiên preferred_username, fallback về name
    username := COALESCE(v_pref_un, v_name);

    -- roles từ resource_access.supabase.roles
    BEGIN
      supa_roles := ARRAY(
        SELECT jsonb_array_elements_text(
          claims->'resource_access'->'supabase'->'roles'
        )
      );
    EXCEPTION WHEN OTHERS THEN
      supa_roles := NULL;
    END;

    -- các field khác
    sess_id       := claims->>'session_state';
    req_id        := claims->>'jti';
    tenant_schema := claims->>'schema';
    cli_ip := COALESCE(
      current_setting('request.header.x-client-ip', true),
      current_setting('request.header.x-forwarded-for', true), 
      inet_client_addr()::TEXT
    );
  END IF;

  -- 3) Lấy realm_roles (nếu đã có v_user_id)
   IF v_user_id IS NOT NULL THEN
    SELECT COALESCE(ARRAY_AGG(r.code), ARRAY[]::TEXT[])
    INTO realm_roles
    FROM user_role ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = v_user_id;
  END IF;

  -- 4) Ghi log vào audit_log
  INSERT INTO audit_log(
    table_name, operation, record_id, old_data, new_data, reason,
    changed_by, actor_name, actor_role, realm_roles,
    session_id, request_id, tenant_schema, client_ip
  ) VALUES (
    table_name, operation, record_id, old_data, new_data, reason,
    v_user_id, username, supa_roles, realm_roles,
    sess_id, req_id, tenant_schema, cli_ip
  );
END;$$;


ALTER FUNCTION public.log_audit(table_name text, operation text, record_id integer, old_data jsonb, new_data jsonb, reason text) OWNER TO postgres;

--
-- Name: merge_child_organizations(integer[], integer, date, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.merge_child_organizations(merging_org_ids integer[], target_org_id integer, date_merge date DEFAULT now(), file_urls text[] DEFAULT NULL::text[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
    child_count INT := 0;
    org_record RECORD;
    tenant_schema TEXT;
    log_id INT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    -- Cập nhật tất cả các đơn vị con của đơn vị bị sáp nhập
    FOR org_record IN 
        SELECT * FROM organizations 
        WHERE parent_org_id = ANY(merging_org_ids) AND is_active = TRUE
    LOOP
       -- Cập nhật parent_org_id cho từng tổ chức con
        UPDATE organizations
        SET 
            parent_org_id = target_org_id,  
            effective_date = date_merge, 
            version = version + 1
        WHERE id = org_record.id;

        -- Ghi log vào `org_log` dùng SELECT thay vì VALUES
        INSERT INTO org_log (
            org_id, target_org_id, action, reason, log_date, code, name, en_name, category_id, parent_org_id,
            location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, version,
            description, general_manager_id, direct_manager_id
        )
        SELECT 
            org_record.id,
            target_org_id,
            'UPDATED PARENT',
            FORMAT('Chuyển đơn vị con %s vào đơn vị %s', org_record.name, target_org_id),
            NOW(),
            org_record.code,
            org_record.name,
            org_record.en_name,
            org_record.category_id,
            target_org_id,
            org_record.location_id,
            org_record.phone,
            org_record.email,
            org_record.effective_date,
            org_record.expired_date,
            org_record.cost_centers_id,
            org_record.is_active,
            org_record.version,
            FORMAT(
                'Đơn vị %s (ID: %s) đã được chuyển thành đơn vị con của %s (ID: %s).',
                org_record.name, org_record.id, target_org_id, target_org_id
            ),
            org_record.general_manager_id,
            org_record.direct_manager_id
        RETURNING id INTO log_id;

        -- Ghi đính kèm file (nếu có)
        PERFORM org_log_attachments_insert(log_id, file_urls);

        -- Tăng biến đếm số đơn vị con đã cập nhật
        child_count := child_count + 1;

    END LOOP;

    -- Trả về số lượng đơn vị con đã cập nhật
    RETURN child_count;
END;
$$;


ALTER FUNCTION public.merge_child_organizations(merging_org_ids integer[], target_org_id integer, date_merge date, file_urls text[]) OWNER TO postgres;

--
-- Name: merge_organizations(integer[], integer, date, character varying, integer, integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.merge_organizations(merging_org_ids integer[], target_org_id integer, date_merge date DEFAULT now(), new_name character varying DEFAULT NULL::character varying, new_location_id integer DEFAULT NULL::integer, new_manager_id integer DEFAULT NULL::integer, new_parent_org_id integer DEFAULT NULL::integer, file_urls text[] DEFAULT NULL::text[]) RETURNS TABLE(status boolean, message text, merged_target_org_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE 
    validation_result TEXT;
    emp_count INT := 0;
    child_count INT := 0;
    merged_orgs TEXT := '';
    org_record RECORD;
    org_id INT;
    emp_total INT;
    tenant_schema TEXT;
    log_id INT;
    log_id_target INT;

BEGIN
    BEGIN

        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- Kiểm tra tính hợp lệ của tổ chức
        validation_result := validate_organizations(merging_org_ids, target_org_id, 'merge');
        IF validation_result <> 'VALID' THEN
            RETURN QUERY SELECT false, validation_result, target_org_id;
            RETURN;
        END IF;

        -- Kiểm tra và chuyển nhân viên
        FOREACH org_id IN ARRAY merging_org_ids LOOP
            emp_total := count_employees_by_org(org_id);

            IF emp_total = -1 THEN
                RAISE EXCEPTION 'Lỗi: Không thể đếm số lượng nhân viên của organization ID: %', org_id;
                RETURN QUERY SELECT false, 'Lỗi: Không thể đếm số lượng nhân viên', target_org_id;
                RETURN;
            ELSIF emp_total > 0 THEN
                emp_count := emp_count + transfer_employees(ARRAY[org_id], target_org_id, date_merge);
            ELSE
                RAISE LOG 'Không có nhân viên trong organization ID: %, bỏ qua', org_id;
            END IF;
        END LOOP;

        -- Chuyển đơn vị con từ tổ chức bị sáp nhập sang tổ chức nhận
        child_count := merge_child_organizations(merging_org_ids, target_org_id, date_merge, file_urls);

        -- Đánh dấu các tổ chức bị sáp nhập là không còn hoạt động
        FOREACH org_id IN ARRAY merging_org_ids LOOP
            UPDATE organizations
            SET is_active = FALSE, expired_date = date_merge, version = version + 1
            WHERE id = org_id;
            
            SELECT * INTO org_record
            FROM organizations
            WHERE id = org_id;

            -- Ghi log
            INSERT INTO org_log (
                org_id, target_org_id, action, reason, log_date, code, name, en_name, category_id, parent_org_id,
                location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, version,
                description, general_manager_id, direct_manager_id
            ) VALUES (
                org_record.id, target_org_id, 'MERGED', 
                FORMAT('Sáp nhập vào tổ chức %s', target_org_id), 
                date_merge, org_record.code ,org_record.name, org_record.en_name, org_record.category_id, org_record.parent_org_id, 
                org_record.location_id, org_record.phone, org_record.email, 
                org_record.effective_date, org_record.expired_date, 
                org_record.cost_centers_id, org_record.is_active, 
                org_record.version,
                FORMAT('Tổ chức %s đã bị sáp nhập vào tổ chức %s. Tất cả nhân viên và đơn vị con đã được chuyển giao.', org_record.id, target_org_id),
                org_record.general_manager_id, org_record.direct_manager_id
            )RETURNING id INTO log_id;

             -- Ghi đính kèm file
            PERFORM org_log_attachments_insert(log_id, file_urls);

            merged_orgs := merged_orgs || FORMAT('%s, ', org_id);
        END LOOP;

        -- Cập nhật thông tin đơn vị B nếu có thay đổi và lấy dữ liệu mới sau update
        UPDATE organizations
        SET 
            name = COALESCE(new_name, name), 
            location_id = COALESCE(new_location_id, location_id),
            effective_date=date_merge,
            parent_org_id = COALESCE(new_parent_org_id, parent_org_id),
            general_manager_id = COALESCE(new_manager_id,general_manager_id),
            version = version + 1
        WHERE id = target_org_id;

        INSERT INTO org_log (
            org_id, target_org_id, action, reason, log_date, code, name, en_name, category_id, parent_org_id,
            location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, version,
            description, general_manager_id, direct_manager_id
        ) SELECT id,  null, 'UPDATE AFTER MERGER',  'Cập nhật thông tin chi tiết về tổ chức trong quá trình sáp nhập', 
            date_merge,  code,  name,  en_name,  category_id, parent_org_id, location_id,  phone,  email,  effective_date, 
            expired_date,  cost_centers_id,  is_active,  version, 
            FORMAT('Tổ chức %s đã nhận sáp nhập từ các tổ chức: %s. Số nhân viên được chuyển: %s, số tổ chức con cập nhật: %s.', 
                    target_org_id, merged_orgs, emp_count, child_count),  general_manager_id, direct_manager_id
        FROM organizations WHERE id = target_org_id
        RETURNING id INTO log_id_target;

        -- Ghi file đính kèm cho tổ chức nhận
        PERFORM org_log_attachments_insert(log_id_target, file_urls);

        -- Logging hoàn thành function
        RAISE LOG 'Merge process completed. Organizations merged: %, Employees transferred: %, Child organizations updated: %', 
                  merged_orgs, emp_count, child_count;

        RETURN QUERY SELECT 
            true,
            FORMAT('Đã sáp nhập tổ chức vào tổ chức (ID %s). Số nhân viên đã chuyển: %s. Số tổ chức con đã cập nhật: %s.', 
            target_org_id, emp_count, child_count),
            target_org_id;

    EXCEPTION 
        WHEN OTHERS THEN
            RAISE LOG 'Lỗi xảy ra khi sáp nhập: %', SQLERRM;
            RETURN QUERY SELECT 
                false, 
                FORMAT('Lỗi khi sáp nhập tổ chức: %s', SQLERRM), 
                target_org_id;
            RETURN;
    END;
END;
$$;


ALTER FUNCTION public.merge_organizations(merging_org_ids integer[], target_org_id integer, date_merge date, new_name character varying, new_location_id integer, new_manager_id integer, new_parent_org_id integer, file_urls text[]) OWNER TO postgres;

--
-- Name: org_log_attachments_insert(integer, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.org_log_attachments_insert(p_log_id integer, p_file_urls text[] DEFAULT NULL::text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_file_urls IS NOT NULL AND array_length(p_file_urls, 1) > 0 THEN
    BEGIN
      INSERT INTO org_log_attachment (log_id, attachment_id)
      SELECT p_log_id, a.id
      FROM unnest(p_file_urls) AS url(file_url)
      JOIN attachments a ON a.file_url = url.file_url; 
    EXCEPTION
      WHEN OTHERS THEN
        RAISE LOG 'Lỗi khi ghi file đính kèm cho log_id %: %', p_log_id, SQLERRM;
    END;
  END IF;
END;
$$;


ALTER FUNCTION public.org_log_attachments_insert(p_log_id integer, p_file_urls text[]) OWNER TO postgres;

--
-- Name: org_log_insert(integer, integer, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.org_log_insert(p_old_org_id integer, p_target_org_id integer, p_action text, p_reason text, p_description text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    log_id INT;
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    INSERT INTO org_log (
        org_id, target_org_id, action, reason, log_date, code, name, en_name, category_id, parent_org_id,
        location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, version,
        description, general_manager_id, direct_manager_id, approve_struct, decision_no, decision_date
    )
    SELECT 
        id, p_target_org_id, p_action, p_reason, NOW(), code, name, en_name, category_id, parent_org_id,
        location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, version,
        COALESCE(p_description, description), general_manager_id, direct_manager_id, approve_struct, decision_no, decision_date
    FROM organizations
    WHERE id = p_old_org_id
    RETURNING id INTO log_id;

    RETURN log_id;
END;
$$;


ALTER FUNCTION public.org_log_insert(p_old_org_id integer, p_target_org_id integer, p_action text, p_reason text, p_description text) OWNER TO postgres;

--
-- Name: organization_add(character varying, character varying, integer, integer, text, text, date, text, date, integer, integer, character varying, character varying, text, text, date, public.approve_struct_enum, integer, integer, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_add(p_code character varying, p_name character varying, p_category_id integer, p_districts_id integer, p_address text, p_address_name text, p_effective_date date, p_en_name text DEFAULT NULL::text, p_expired_date date DEFAULT NULL::date, p_location_id integer DEFAULT NULL::integer, p_parent_org_id integer DEFAULT NULL::integer, p_phone character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_decision_no text DEFAULT NULL::text, p_decision_date date DEFAULT NULL::date, p_approve_struct public.approve_struct_enum DEFAULT NULL::public.approve_struct_enum, p_cost_center_id integer DEFAULT NULL::integer, p_general_manager_id integer DEFAULT NULL::integer, p_direct_manager_id integer DEFAULT NULL::integer, files jsonb DEFAULT '[]'::jsonb) RETURNS TABLE(status boolean, message text, organization_id integer, org_log_id integer)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_org_id INT;
    v_org_log_id INT;
    v_location_id INT;
    v_error TEXT DEFAULT NULL;
    tenant_schema TEXT;
    file JSONB;
    attachment_result RECORD;
    v_attachment_id INT;
BEGIN
    BEGIN

        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
        -- Thiết lập search_path theo schema
        EXECUTE format('SET search_path TO %I', tenant_schema);
        -- Kiểm tra nếu p_location_id có tồn tại trong bảng locations
        
        IF p_location_id IS NOT NULL AND p_location_id > 0 THEN
            IF NOT EXISTS (SELECT 1 FROM locations WHERE id = p_location_id) THEN
                v_error := 'Không tìm thấy địa điểm';  
            ELSE
                v_location_id := p_location_id;
                RAISE NOTICE 'Sử dụng địa điểm có sẵn với ID: %', v_location_id;
            END IF;
        END IF;
 
        -- Nếu v_location_id chưa được set (do location_id không hợp lệ), tạo mới
        IF v_location_id IS NULL THEN
            INSERT INTO locations (districts_id, address, name)
            VALUES (p_districts_id, p_address, p_address_name)
            RETURNING id INTO v_location_id;
            RAISE NOTICE 'Đã tạo địa điểm mới với ID: %', v_location_id;
        END IF;

        IF EXISTS(SELECT 1 FROM organizations WHERE code = p_code) THEN
            RETURN QUERY SELECT
            false, 'Mã đơn vị đã tồn tại, vui lòng chọn mã mới', NULL::INT, NULL::INT;
            RETURN;
        END IF;    

        -- Kiểm tra điều kiện cập nhật
        PERFORM validate_organization_data(  p_category_id, p_effective_date, p_parent_org_id, 
        p_general_manager_id, p_direct_manager_id, p_name, p_en_name, null, null, p_phone, p_email );
 
        -- Tạo tổ chức
        INSERT INTO organizations (
            code, name, en_name, category_id, parent_org_id, location_id, effective_date,
            phone, email, description, expired_date, cost_centers_id, decision_no, decision_date, approve_struct,general_manager_id ,direct_manager_id
        ) VALUES (
            p_code, p_name, p_en_name, p_category_id, p_parent_org_id, v_location_id, p_effective_date,
            p_phone, p_email, p_description, p_expired_date, p_cost_center_id, p_decision_no, p_decision_date, p_approve_struct,p_general_manager_id,p_direct_manager_id
        )
        RETURNING id INTO v_org_id;
 
        RAISE NOTICE 'Đã tạo tổ chức với ID: %', v_org_id;
 
        -- Ghi log vào org_log
        v_org_log_id := org_log_insert ( v_org_id, null, 'CREATE', 'Tạo mới tổ chức',p_description);
 
        RAISE NOTICE 'Đã ghi log cho tổ chức ID: %', v_org_id;
        

        -- Lặp qua từng file trong danh sách files
        FOR file IN SELECT value FROM jsonb_array_elements(files) AS value LOOP
            -- Gọi function attachment_add cho từng file
            SELECT * INTO attachment_result
            FROM attachment_os_add(
                'organizations',          -- p_target_table
                ARRAY[v_org_id],     -- p_target_ids
                file                      -- p_json_input
            );

            -- Kiểm tra kết quả của attachment_add
            IF NOT attachment_result.success THEN
                RAISE EXCEPTION 'Lỗi khi thêm tệp đính kèm: %', attachment_result.message;
            END IF;

            v_attachment_id := attachment_result.attachment_id;

            -- Ghi log vào org_log_attachments
            INSERT INTO org_log_attachment (
                log_id, attachment_id
            ) VALUES (
                v_org_log_id, v_attachment_id
            );
        END LOOP;

        -- Trả về ID tổ chức mới tạo
          RETURN QUERY SELECT 
            true,
            'Tạo tổ chức thành công',
            v_org_id,
            v_org_log_id;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE LOG 'Lỗi: %', SQLERRM;
        RETURN QUERY SELECT FALSE, SQLERRM, NULL::INT, NULL::INT;
    END;
END;$$;


ALTER FUNCTION public.organization_add(p_code character varying, p_name character varying, p_category_id integer, p_districts_id integer, p_address text, p_address_name text, p_effective_date date, p_en_name text, p_expired_date date, p_location_id integer, p_parent_org_id integer, p_phone character varying, p_email character varying, p_description text, p_decision_no text, p_decision_date date, p_approve_struct public.approve_struct_enum, p_cost_center_id integer, p_general_manager_id integer, p_direct_manager_id integer, files jsonb) OWNER TO postgres;

--
-- Name: organization_build_tree(integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_build_tree(p_parent_id integer, p_current_depth integer, p_max_depth integer, p_search_by_is_active boolean DEFAULT NULL::boolean) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$DECLARE
    result JSONB;
BEGIN
    IF p_current_depth > p_max_depth THEN
        RETURN '[]'::JSONB;
    END IF;
    SELECT jsonb_agg(
      jsonb_build_object(
         'id', o.id,
         'name', o.name,
         'code', o.code,
         'category_id', o.category_id,
         'category_name', e.name,
         'is_active', o.is_active,
         'children', organization_build_tree(
                        o.id,
                        p_current_depth + 1,
                        p_max_depth,
                        p_search_by_is_active
                     )
      )
    )
    INTO result
    FROM organizations o
    LEFT JOIN enum_lookup e ON o.category_id = e.id
    WHERE 
         (
            (p_parent_id IS NULL AND o.parent_org_id IS NULL) 
         OR (p_parent_id IS NOT NULL AND o.parent_org_id = p_parent_id)
         )
         AND (p_search_by_is_active IS NULL OR o.is_active = p_search_by_is_active);
    RETURN COALESCE(result, '[]'::JSONB);
END;$$;


ALTER FUNCTION public.organization_build_tree(p_parent_id integer, p_current_depth integer, p_max_depth integer, p_search_by_is_active boolean) OWNER TO postgres;

--
-- Name: organization_dissolve(integer, date, text, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_dissolve(p_org_id integer, p_dissolve_date date, p_reason text, file_urls text[] DEFAULT NULL::text[]) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_org RECORD;
    tenant_schema TEXT;
    log_id INT;
    validation_result RECORD;
BEGIN
    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- -- Gọi hàm validate_organization_dissolve để kiểm tra tính hợp lệ
    -- SELECT * INTO validation_result FROM validate_organization_dissolve(p_org_id);
    -- IF NOT validation_result.status THEN
    --     RETURN QUERY SELECT validation_result.status, validation_result.message;
    --     RETURN;
    -- END IF;

    -- Cập nhật trạng thái của đơn vị
    UPDATE organizations
    SET is_active = FALSE, expired_date = p_dissolve_date, version = version + 1
    WHERE id = p_org_id
    RETURNING * INTO v_org;

    -- Ghi log vào org_log
    log_id :=  org_log_insert (
        v_org.id, null,'DISSOLVE', p_reason, v_org.description
    );

    -- Ghi đính kèm file
    PERFORM org_log_attachments_insert(log_id, file_urls);

    -- Trả về kết quả thành công
    RETURN QUERY SELECT TRUE, 'Giải thể tổ chức thành công';

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, 'Lỗi khi giải thể: ' || SQLERRM;
END;$$;


ALTER FUNCTION public.organization_dissolve(p_org_id integer, p_dissolve_date date, p_reason text, file_urls text[]) OWNER TO postgres;

--
-- Name: organization_dissolve_with_attachment(integer, date, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_dissolve_with_attachment(p_org_id integer, p_dissolve_date date, p_reason text, files jsonb DEFAULT '[]'::jsonb) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    file JSONB;
    attachment_result RECORD;
    dissolve_result RECORD;
    validation_result RECORD;
BEGIN
    BEGIN

        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- Gọi hàm validate_organization_dissolve để kiểm tra tính hợp lệ
        SELECT * INTO validation_result FROM validate_organization_dissolve(p_org_id);
        IF NOT validation_result.status THEN
            RETURN QUERY SELECT validation_result.status, validation_result.message;
            RETURN;
        END IF;

        -- Lặp qua từng file trong danh sách files
        FOR file IN SELECT value FROM jsonb_array_elements(files) AS value LOOP
            -- Gọi function attachment_add cho từng file
            SELECT * INTO attachment_result
            FROM attachment_os_add(
                'organizations',          -- p_target_table
                ARRAY[p_org_id],     -- p_target_ids
                file                      -- p_json_input
            );

            -- Kiểm tra kết quả của add_attachment
            IF NOT attachment_result.success THEN
                RAISE EXCEPTION 'Thêm file thất bại: %', attachment_result.message;
            END IF;
        END LOOP;

        SELECT * INTO dissolve_result
        FROM organization_dissolve(
            p_org_id,                  -- ID đơn vị cần giải thể
            p_dissolve_date,          -- Ngày giải thể
            p_reason,                   -- Lý do giải thể
            ARRAY(SELECT file->>'file_url' FROM jsonb_array_elements(files))
        );

        -- Kiểm tra kết quả của organization_dissolve
        IF NOT dissolve_result.status THEN
            RETURN QUERY SELECT FALSE, 'Giải thể tổ chức thất bại: ' || dissolve_result.message;
        END IF;

        -- Trả về kết quả thành công
        RETURN QUERY SELECT TRUE, 'Giải thể tổ chức thành công';
    EXCEPTION
        WHEN OTHERS THEN
            -- Trả về thông báo lỗi nếu có lỗi xảy ra
            RETURN QUERY SELECT FALSE, 'Lỗi khi giải thể: ' || SQLERRM;
    END;
END;
$$;


ALTER FUNCTION public.organization_dissolve_with_attachment(p_org_id integer, p_dissolve_date date, p_reason text, files jsonb) OWNER TO postgres;

--
-- Name: organization_get_childs(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_get_childs(p_org_id integer, p_category_code text DEFAULT NULL::text, p_level integer DEFAULT NULL::integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$DECLARE
    max_depth_for_category INT;
    result_ids INT[];
BEGIN
    -- Nếu lọc theo category_code, tính depth tối đa
    IF p_category_code IS NOT NULL THEN
        WITH RECURSIVE child_cte AS (
            SELECT id, parent_org_id, 1 AS depth
            FROM organizations
            WHERE id = p_org_id
          UNION ALL
            SELECT c.id, c.parent_org_id, child_cte.depth + 1
            FROM organizations c
            JOIN child_cte ON c.parent_org_id = child_cte.id
        )
        SELECT MIN(child_cte.depth)
          INTO max_depth_for_category
        FROM child_cte
        JOIN enum_lookup el ON child_cte.id = el.id
        WHERE el.code = p_category_code;
    END IF;
 
    -- Gom các id vào mảng, loại bỏ id gốc, áp dụng các điều kiện p_level và p_category_code
    WITH RECURSIVE child_cte AS (
        SELECT o.id, o.parent_org_id, 1 AS depth
        FROM organizations o
        WHERE o.id = p_org_id
      UNION ALL
        SELECT c.id, c.parent_org_id, child_cte.depth + 1
        FROM organizations c
        JOIN child_cte ON c.parent_org_id = child_cte.id
    )
    SELECT ARRAY_AGG(cte.id ORDER BY cte.depth, cte.id)
      INTO result_ids
    FROM child_cte cte
    WHERE cte.id <> p_org_id
      AND (p_level IS NULL OR cte.depth <= p_level)
      AND (p_category_code IS NULL OR (max_depth_for_category IS NOT NULL AND cte.depth <= max_depth_for_category));
 
    RETURN result_ids;
END;$$;


ALTER FUNCTION public.organization_get_childs(p_org_id integer, p_category_code text, p_level integer) OWNER TO postgres;

--
-- Name: organization_get_max_depth(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_get_max_depth() RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
    m INT;
BEGIN
    WITH RECURSIVE org_cte AS (
        -- Bắt đầu từ các node gốc
        SELECT 
            id, 
            parent_org_id, 
            1 AS depth
        FROM organizations
        WHERE parent_org_id IS NULL
        UNION ALL
        -- Lấy các node con và tăng depth
        SELECT 
            o.id,
            o.parent_org_id,
            cte.depth + 1 AS depth
        FROM organizations o
        JOIN org_cte cte ON o.parent_org_id = cte.id
    )
    SELECT MAX(depth) INTO m FROM org_cte;
    RETURN COALESCE(m, 0);
END;$$;


ALTER FUNCTION public.organization_get_max_depth() OWNER TO postgres;

--
-- Name: organization_get_parents(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_get_parents(p_org_id integer, p_category_code text DEFAULT NULL::text, p_level integer DEFAULT NULL::integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_depth_for_category INT;
    result_ids INT[];
BEGIN
    -- Nếu lọc theo category_code, tính depth tối đa
    IF p_category_code IS NOT NULL THEN
        WITH RECURSIVE parent_cte AS (
            SELECT id, parent_org_id, 1 AS depth
            FROM organizations
            WHERE id = p_org_id
          UNION ALL
            SELECT o.id, o.parent_org_id, parent_cte.depth + 1
            FROM organizations o
            JOIN parent_cte ON o.id = parent_cte.parent_org_id
        )
        SELECT MIN(parent_cte.depth)
          INTO max_depth_for_category
        FROM parent_cte
        JOIN enum_lookup el ON parent_cte.id = el.id
        WHERE el.code = p_category_code;
    END IF;

    -- Gom các id vào mảng, loại bỏ id gốc, áp dụng các điều kiện p_level và p_category_code
    WITH RECURSIVE parent_cte AS (
        SELECT o.id, o.parent_org_id, 1 AS depth
        FROM organizations o
        WHERE o.id = p_org_id
      UNION ALL
        SELECT o.id, o.parent_org_id, parent_cte.depth + 1
        FROM organizations o
        JOIN parent_cte ON o.id = parent_cte.parent_org_id
    )
    SELECT ARRAY_AGG(cte.id ORDER BY cte.depth)
      INTO result_ids
    FROM parent_cte cte
    WHERE cte.id <> p_org_id
      AND (p_level IS NULL OR cte.depth <= p_level)
      AND (p_category_code IS NULL OR (max_depth_for_category IS NOT NULL AND cte.depth <= max_depth_for_category));

    RETURN result_ids;
END;
$$;


ALTER FUNCTION public.organization_get_parents(p_org_id integer, p_category_code text, p_level integer) OWNER TO postgres;

--
-- Name: organization_get_tree(boolean, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_get_tree(p_is_active boolean DEFAULT true, p_max_depth integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    full_tree JSONB;
    pruned_tree JSONB;
    max_depth INT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
 
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);
 
    -- Nếu có từ khóa, cần lấy max_depth tự động
    IF p_keyword IS NOT NULL THEN
        max_depth := organization_get_max_depth();  -- Lấy độ sâu tối đa
        full_tree := organization_build_tree(NULL,1, max_depth, p_is_active);
        pruned_tree := organization_prune_tree_by_keyword(full_tree, p_keyword);
        RETURN pruned_tree;
    ELSE
        -- Nếu không có từ khóa, lấy theo max_depth được truyền vào (hoặc mặc định)
        RETURN organization_build_tree(NULL::integer,1, p_max_depth, p_is_active);
    END IF;
END;
$$;


ALTER FUNCTION public.organization_get_tree(p_is_active boolean, p_max_depth integer, p_keyword text) OWNER TO postgres;

--
-- Name: organization_get_tree_by_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_get_tree_by_id(p_org_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$DECLARE
    tenant_schema TEXT;
    root_org JSONB;
    ancestor_tree JSONB;
    descendant_tree JSONB;
    result_tree JSONB;
    root_parent_id INT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
 
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);
 
    -- 🔹 Lấy thông tin của chính `p_org_id`
    SELECT jsonb_build_object(
        'id', id,
        'name', name,
        'code', code,
        'parent_org_id', parent_org_id,
        'category_name', category_name,
        'is_active', is_active
    ), parent_org_id
    INTO root_org, root_parent_id
    FROM organization_details_view
    WHERE id = p_org_id;
 
    -- 🔹 Lấy danh sách tổ tiên (cha, ông, cụ,...)
    WITH RECURSIVE ancestors AS (
        SELECT id, name, code, parent_org_id, category_name, is_active
        FROM organization_details_view
        WHERE id = root_parent_id
        UNION ALL
        SELECT o.id, o.name, o.code, o.parent_org_id, o.category_name, o.is_active
        FROM organization_details_view o
        JOIN ancestors a ON o.id = a.parent_org_id
    )
    SELECT jsonb_agg(jsonb_build_object(
        'id', id,
        'name', name,
        'code', code,
        'parent_org_id', parent_org_id,
        'category_name', category_name,
        'is_active', is_active
    ))
    INTO ancestor_tree
    FROM ancestors;
 
    -- 🔹 Lấy danh sách con cháu (con, cháu, chắt,...)
    WITH RECURSIVE descendants AS (
        SELECT id, name, code, parent_org_id, category_name, is_active
        FROM organization_details_view
        WHERE parent_org_id = p_org_id
        UNION ALL
        SELECT o.id, o.name, o.code, o.parent_org_id, o.category_name, o.is_active
        FROM organization_details_view o
        JOIN descendants d ON o.parent_org_id = d.id
    )
    SELECT jsonb_agg(jsonb_build_object(
        'id', id,
        'name', name,
        'code', code,
        'parent_org_id', parent_org_id,
        'category_name', category_name,
        'is_active', is_active
    ))
    INTO descendant_tree
    FROM descendants;
 
    -- 🔹 Gộp tất cả dữ liệu lại (root + ancestors + descendants)
    result_tree := jsonb_build_array(root_org) || COALESCE(ancestor_tree, '[]'::jsonb) || COALESCE(descendant_tree, '[]'::jsonb);
 
    RETURN result_tree;
END;$$;


ALTER FUNCTION public.organization_get_tree_by_id(p_org_id integer) OWNER TO postgres;

--
-- Name: organization_merge(integer[], integer, date, character varying, integer, integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_merge(merging_org_ids integer[], target_org_id integer, date_merge date DEFAULT now(), new_name character varying DEFAULT NULL::character varying, new_location_id integer DEFAULT NULL::integer, new_manager_id integer DEFAULT NULL::integer, new_parent_org_id integer DEFAULT NULL::integer, file_urls text[] DEFAULT NULL::text[]) RETURNS TABLE(status boolean, message text, merged_target_org_id integer)
    LANGUAGE plpgsql
    AS $$DECLARE 
    validation_result TEXT;
    emp_count INT := 0;
    child_count INT := 0;
    merged_orgs TEXT := '';
    org_record RECORD;
    org_id INT;
    emp_total INT;
    tenant_schema TEXT;
    log_id INT;
    log_id_target INT;

BEGIN
    BEGIN

        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- Kiểm tra tính hợp lệ của tổ chức
        validation_result := validate_organizations(merging_org_ids, target_org_id, 'merge');
        IF validation_result <> 'VALID' THEN
             RAISE EXCEPTION '%', validation_result; 
        END IF;
        
        -- Chuyển đơn vị con từ tổ chức bị sáp nhập sang tổ chức nhận
        child_count := organizations_merge_child(merging_org_ids, target_org_id, date_merge, file_urls);

        -- Đánh dấu các tổ chức bị sáp nhập là không còn hoạt động
        FOREACH org_id IN ARRAY merging_org_ids LOOP
            
            UPDATE organizations
            SET is_active = FALSE, expired_date = date_merge, version = version + 1
            WHERE id = org_id;
            
            SELECT * INTO org_record
            FROM organizations
            WHERE id = org_id;

            -- Ghi log
            log_id := org_log_insert (
                org_record.id, target_org_id, 'MERGED', 
                FORMAT('Sáp nhập vào tổ chức %s', target_org_id),
                FORMAT('Tổ chức %s đã bị sáp nhập vào tổ chức %s. Tất cả nhân viên và đơn vị con đã được chuyển giao.', org_record.id, target_org_id)
            );

             -- Ghi đính kèm file
            PERFORM org_log_attachments_insert(log_id, file_urls);

            merged_orgs := merged_orgs || FORMAT('%s, ', org_id);
        END LOOP;

        -- Cập nhật thông tin đơn vị B nếu có thay đổi và lấy dữ liệu mới sau update
        UPDATE organizations
        SET 
            name = COALESCE(new_name, name), 
            location_id = COALESCE(new_location_id, location_id),
            effective_date=date_merge,
            parent_org_id = COALESCE(new_parent_org_id, parent_org_id),
            general_manager_id = COALESCE(new_manager_id,general_manager_id),
            version = version + 1
        WHERE id = target_org_id;

        log_id_target := org_log_insert ( target_org_id,  null, 'UPDATE AFTER MERGER',  
            'Cập nhật thông tin chi tiết về tổ chức trong quá trình sáp nhập', 
            FORMAT('Tổ chức %s đã nhận sáp nhập từ các tổ chức: %s. Số nhân viên được chuyển: %s, số tổ chức con cập nhật: %s.', 
                    target_org_id, merged_orgs, emp_count, child_count)
        );
        
        -- Ghi file đính kèm cho tổ chức nhận
        PERFORM org_log_attachments_insert(log_id_target, file_urls);

        RETURN QUERY SELECT 
            true,
            FORMAT('Đã sáp nhập tổ chức vào tổ chức (ID %s). Số nhân viên đã chuyển: %s. Số tổ chức con đã cập nhật: %s.', 
            target_org_id, emp_count, child_count),
            target_org_id;

    EXCEPTION 
        WHEN OTHERS THEN
            RAISE LOG 'Lỗi xảy ra khi sáp nhập: %', SQLERRM;
            RETURN QUERY SELECT 
                false, 
                FORMAT('Lỗi khi sáp nhập tổ chức: %s', SQLERRM), 
                target_org_id;
            RETURN;
    END;
END;$$;


ALTER FUNCTION public.organization_merge(merging_org_ids integer[], target_org_id integer, date_merge date, new_name character varying, new_location_id integer, new_manager_id integer, new_parent_org_id integer, file_urls text[]) OWNER TO postgres;

--
-- Name: organization_merge_with_attachment(integer[], integer, date, character varying, integer, integer, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_merge_with_attachment(merging_org_ids integer[], target_org_id integer, date_merge date DEFAULT now(), new_name character varying DEFAULT NULL::character varying, new_location_id integer DEFAULT NULL::integer, new_manager_id integer DEFAULT NULL::integer, new_parent_org_id integer DEFAULT NULL::integer, files jsonb DEFAULT '[]'::jsonb) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    validation_result TEXT;
    file JSONB;
    tenant_schema TEXT;
    attachment_result RECORD;
    merge_result RECORD;
    file_urls TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Bắt đầu transaction
    BEGIN
        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- Kiểm tra tính hợp lệ của tổ chức
        validation_result := validate_organizations(merging_org_ids, target_org_id, 'merge');
        IF validation_result <> 'VALID' THEN
            RAISE EXCEPTION '%', validation_result; 
        END IF;


        -- Lặp qua từng file trong danh sách files
        FOR file IN SELECT value FROM jsonb_array_elements(files) AS value LOOP
            -- Gọi function attachment_add cho từng file
            SELECT * INTO attachment_result
            FROM attachment_os_add(
                'organizations',          -- p_target_table
                ARRAY[target_org_id] || merging_org_ids,     -- p_target_ids
                file                      -- p_json_input
            );

            -- Kiểm tra kết quả của add_attachment
            IF NOT attachment_result.success THEN
                RAISE EXCEPTION 'Thêm file thất bại: %', attachment_result.message;
            END IF;

            file_urls := file_urls || (file->>'file_url');
        END LOOP;

        -- Gọi function organization_merge sau khi lưu tất cả file đính kèm thành công
        SELECT * INTO merge_result
        FROM organization_merge(
            merging_org_ids, 
            target_org_id, 
            date_merge, 
            new_name, 
            new_location_id, 
            new_manager_id, 
            new_parent_org_id, 
            file_urls
        );

        -- Kiểm tra kết quả của organization_merge
        IF NOT merge_result.status THEN
            RAISE EXCEPTION 'Sáp nhập tổ chức thất bại: %', merge_result.message;
        END IF;

        -- Nếu thành công
        RETURN QUERY SELECT TRUE, 'Thêm file đính kèm và sáp nhập tổ chức thành công';

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaction nếu có lỗi
            RAISE LOG 'Lỗi xảy ra trong quá trình thực thi: %', SQLERRM;
            RETURN QUERY SELECT FALSE, FORMAT('Lỗi: %s', SQLERRM);
    END;
END;
$$;


ALTER FUNCTION public.organization_merge_with_attachment(merging_org_ids integer[], target_org_id integer, date_merge date, new_name character varying, new_location_id integer, new_manager_id integer, new_parent_org_id integer, files jsonb) OWNER TO postgres;

--
-- Name: organization_rollback(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_rollback(p_organization_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE 
  tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    -- Bắt đầu giao dịch
    BEGIN
        -- Xóa bản ghi trong bảng org_log trước để tránh vi phạm khóa ngoại
        DELETE FROM org_log
        WHERE org_id = p_organization_id;

        -- Xóa bản ghi trong bảng organizations
        DELETE FROM organizations
        WHERE id = p_organization_id;

        -- Trả về kết quả thành công
        RETURN QUERY SELECT TRUE, 'Xóa organization thành công';
    EXCEPTION
        WHEN foreign_key_violation THEN
            -- Trường hợp vi phạm khóa ngoại
            RETURN QUERY SELECT FALSE, 'Không thể xóa vì có ràng buộc khóa ngoại';

        WHEN OTHERS THEN
            -- In ra thông báo lỗi chi tiết để dễ gỡ lỗi
            RAISE NOTICE 'Lỗi khi xóa organization với ID %: %', p_organization_id, SQLERRM;
            RETURN QUERY SELECT FALSE, 'Lỗi không xác định: ' || SQLERRM;
    END;
END;
$$;


ALTER FUNCTION public.organization_rollback(p_organization_id integer) OWNER TO postgres;

--
-- Name: organization_split(date, integer, integer[], jsonb, jsonb, text, boolean, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_split(date_split date, p_old_org_id integer, p_new_orgs integer[], p_employee_movement jsonb, p_sub_org_movement jsonb, p_reason text, p_old_org_active boolean, file_urls text[] DEFAULT NULL::text[]) RETURNS TABLE(status boolean, message text, split_target_org_id integer)
    LANGUAGE plpgsql
    AS $$DECLARE
    validation_result TEXT;
    num_invalid_emp INT := 0;
    num_invalid_sub_org INT := 0;
    sub_org RECORD;
    empl RECORD;
    org_count INT := 0; 
    org_log_id INT; 
    org_data RECORD;
    log_id INT;
    tenant_schema TEXT;
    org_log_att_id INT;
BEGIN
    BEGIN
        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- Kiểm tra tính hợp lệ của tổ chức
        validation_result := validate_organizations(p_new_orgs, p_old_org_id, 'split');
        IF validation_result <> 'VALID' THEN
            RAISE EXCEPTION '%', validation_result; 
        END IF;

        -- 🔹 Bước 2: Tạo bảng tạm lưu danh sách di chuyển nhân viên & đơn vị con
        CREATE TEMP TABLE temp_employee_movement (
            employee_id INT PRIMARY KEY,
            new_org_id INT
        )ON COMMIT DROP;

        CREATE TEMP TABLE temp_sub_org_movement (
            sub_org_id INT PRIMARY KEY,
            new_org_id INT
        )ON COMMIT DROP;

        -- 🔹 Bước 3: Chèn dữ liệu từ JSONB vào bảng tạm
        IF jsonb_array_length(COALESCE(p_employee_movement, '[]'::JSONB)) > 0 THEN
            INSERT INTO temp_employee_movement (employee_id, new_org_id)
            SELECT (emp->>'employee_id')::INT, (emp->>'new_org_id')::INT
            FROM jsonb_array_elements(p_employee_movement) AS emp;
        END IF;

        IF jsonb_array_length(COALESCE(p_sub_org_movement, '[]'::JSONB)) > 0 THEN
            INSERT INTO temp_sub_org_movement (sub_org_id, new_org_id)
            SELECT (sub->>'sub_org_id')::INT, (sub->>'new_org_id')::INT
            FROM jsonb_array_elements(p_sub_org_movement) AS sub;
        END IF;

        -- 🔹 Bước 4: Kiểm tra dữ liệu trước khi thực hiện chia tách
        -- 4.1 Kiểm tra nhân viên có thuộc đơn vị chia tách không
        SELECT COUNT(*) INTO num_invalid_emp 
        FROM temp_employee_movement tem
        LEFT JOIN employees emp ON tem.employee_id = emp.id
        WHERE emp.organization_id != p_old_org_id AND date_resign IS NULL;

        IF num_invalid_emp > 0 THEN
            RAISE EXCEPTION 'Có nhân viên không thuộc đơn vị %! Kiểm tra lại danh sách!', p_old_org_id;
        END IF;

        -- 4.2 Kiểm tra đơn vị con có thuộc đơn vị chia tách không
        SELECT COUNT(*) INTO num_invalid_sub_org 
        FROM temp_sub_org_movement tsm
        LEFT JOIN organizations org ON tsm.sub_org_id = org.id
        WHERE org.parent_org_id != p_old_org_id OR org.is_active = FALSE;

        IF num_invalid_sub_org > 0 THEN
            RAISE EXCEPTION 'Có đơn vị con không thuộc đơn vị %! Kiểm tra lại danh sách!', p_old_org_id;
        END IF;

        -- 4.3 Nếu đơn vị tách bị giải thể (`is_active = FALSE`) sau khi chia tách, thì bắt buộc tất cả nhân viên & đơn vị con phải được di chuyển.
        IF p_old_org_active = FALSE THEN
            -- 🔹 Kiểm tra tổng số nhân viên chưa được di chuyển HOẶC không chuyển vào đúng đơn vị mới
            SELECT COUNT(*) INTO num_invalid_emp
            FROM employees emp
            LEFT JOIN temp_employee_movement tem ON emp.id = tem.employee_id
            WHERE emp.organization_id = p_old_org_id 
              AND emp.date_resign IS NULL
              AND (tem.new_org_id IS NULL OR tem.new_org_id NOT IN (SELECT unnest(p_new_orgs)));

            -- 🔹 Kiểm tra tổng số đơn vị con chưa được di chuyển HOẶC không chuyển vào đúng đơn vị mới
            SELECT COUNT(*) INTO num_invalid_sub_org
            FROM organizations org
            LEFT JOIN temp_sub_org_movement tsm ON org.id = tsm.sub_org_id
            WHERE org.parent_org_id = p_old_org_id 
              AND org.is_active = TRUE 
              AND (tsm.new_org_id IS NULL OR tsm.new_org_id NOT IN (SELECT unnest(p_new_orgs)));

            -- Nếu có nhân viên hoặc đơn vị con chưa được chuyển sang tổ chức mới → báo lỗi
            IF num_invalid_emp > 0 OR num_invalid_sub_org > 0 THEN
                RAISE EXCEPTION 'Đơn vị % bị giải thể sau khi chia tách! Toàn bộ % nhân viên và % đơn vị con phải được điều chuyển vào đơn vị mới!', 
                p_old_org_id, num_invalid_emp, num_invalid_sub_org;
            END IF;
        END IF;


        FOR empl IN 
            SELECT emp.id
            FROM employees emp
            JOIN temp_employee_movement tem ON emp.id = tem.employee_id
            WHERE emp.date_resign IS NULL
        LOOP
            PERFORM work_histories_insert(
                p_emp_id           := empl.id,
                p_end_date         := date_split,
                p_reason           := COALESCE(p_reason, FORMAT('Chuyển đơn vị do chia tách từ tổ chức %s', p_old_org_id))
            );
        END LOOP;
        

        -- 🔹 Bước 6: Cập nhật tổ chức mới cho nhân viên (Tối ưu không dùng `LOOP`)
        UPDATE employees e
        SET organization_id = tem.new_org_id, start_date_change = date_split,
            job_change_type = FORMAT('Chia tách từ đơn vị %s', p_old_org_id)
        FROM temp_employee_movement tem
        WHERE e.id = tem.employee_id AND e.date_resign IS NULL;
    
        -- 🔹 Bước 7: Duyệt từng đơn vị con trong `temp_sub_org_movement`
        FOR sub_org IN 
            SELECT tsm.sub_org_id, tsm.new_org_id
            FROM temp_sub_org_movement tsm
        LOOP
            -- 🔹 Cập nhật đơn vị con sang đơn vị mới
            UPDATE organizations
            SET parent_org_id = sub_org.new_org_id, effective_date = date_split,version = version + 1
            WHERE id = sub_org.sub_org_id;

            -- 🔹 Lấy dữ liệu mới nhất từ `organizations` sau khi cập nhật
            SELECT * INTO sub_org
            FROM organizations
            WHERE id = sub_org.sub_org_id;

            -- Ghi log vào `org_log`
            org_log_att_id := org_log_insert( sub_org.id, p_old_org_id, 'SPLIT PARENT', p_reason, FORMAT('Đơn vị con %s đã tách khỏi %s được chuyển sang %s', sub_org.name, p_old_org_id, sub_org.parent_org_id) );
             -- Ghi đính kèm file
            PERFORM org_log_attachments_insert(org_log_att_id, file_urls);

            -- 🔹 Tăng biến đếm lên 1 sau mỗi lần xử lý một đơn vị con
            org_count := org_count + 1;
        END LOOP;

        -- 🔹 Ghi nhận lịch sử tổ chức mới được chia tách từ tổ chức cũ
        FOREACH log_id IN ARRAY p_new_orgs LOOP

            UPDATE organizations
            SET effective_date = date_split, version = version + 1,
                description = p_reason
            WHERE id = log_id;

            -- Lấy thông tin của tổ chức mới sau khi cập nhật
            SELECT * INTO org_data FROM organizations WHERE id = log_id;

            -- Ghi log vào org_log
            org_log_id := org_log_insert( org_data.id, p_old_org_id, 'SPLIT', p_reason, FORMAT('Đơn vị mới %s được tạo từ đơn vị %s', org_data.name, p_old_org_id) );


             -- Ghi đính kèm file
            PERFORM org_log_attachments_insert(org_log_id, file_urls);

            -- Ghi log vào org_log_detail
            INSERT INTO org_log_detail (org_log_id, target_org_id)
            VALUES (org_log_id, log_id);

        END LOOP;

        -- Nếu là false thì đơn vị chịa tách được nhận là chuyển trang thái là false
        IF p_old_org_active = FALSE THEN
            
            UPDATE organizations
            SET is_active = false, effective_date=date_split, expired_date=date_split, version = version + 1
            WHERE id = p_old_org_id;

            log_id := org_log_insert( p_old_org_id, NULL, 'UPDATE AFTER SPLIT', p_reason, FORMAT('Đơn vị %s đã bị giải thể sau khi chia tách ra các đơn vị mới: %s', p_old_org_id, array_to_string(p_new_orgs, ', '))
            );

            -- Ghi đính kèm file
            PERFORM org_log_attachments_insert(log_id, file_urls);

        ELSE
            -- Nếu tổ chức gốc vẫn tiếp tục hoạt động
            UPDATE organizations
            SET effective_date=date_split, version = version + 1
            WHERE id = p_old_org_id;

            -- Chuyển mảng ID đơn vị mới thành chuỗi mô tả
            log_id := org_log_insert( p_old_org_id, NULL, 'UPDATE AFTER SPLIT', p_reason, FORMAT('Đơn vị %s đã chia tách và tạo ra các đơn vị mới: %s', p_old_org_id, array_to_string(p_new_orgs, ', ')) );

            -- Ghi đính kèm file
            PERFORM org_log_attachments_insert(log_id, file_urls);

        END IF;


        RETURN QUERY SELECT TRUE, 'Chia tách tổ chức thành công!', p_old_org_id;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN QUERY SELECT FALSE, 
            FORMAT('Lỗi khi chi tách tổ chức: %s', SQLERRM), 
            p_old_org_id;
    END;
END;$$;


ALTER FUNCTION public.organization_split(date_split date, p_old_org_id integer, p_new_orgs integer[], p_employee_movement jsonb, p_sub_org_movement jsonb, p_reason text, p_old_org_active boolean, file_urls text[]) OWNER TO postgres;

--
-- Name: organization_split_with_attachment(date, integer, integer[], jsonb, jsonb, text, boolean, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_split_with_attachment(date_split date, p_old_org_id integer, p_new_orgs integer[], p_employee_movement jsonb, p_sub_org_movement jsonb, p_reason text, p_old_org_active boolean, files jsonb DEFAULT '[]'::jsonb) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    validation_result TEXT;
    file JSONB;
    tenant_schema TEXT;
    attachment_result RECORD;
    split_result RECORD;
    file_urls TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Bắt đầu transaction
    BEGIN
        -- Lấy schema từ JWT
        tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

        -- Thiết lập search_path theo schema
        PERFORM set_config('search_path', tenant_schema, true);

        -- Kiểm tra tính hợp lệ của tổ chức
        validation_result := validate_organizations(p_new_orgs, p_old_org_id, 'split');
        IF validation_result <> 'VALID' THEN
            RETURN QUERY SELECT FALSE, validation_result;
        END IF;

        -- Lặp qua từng file trong danh sách files
        FOR file IN SELECT value FROM jsonb_array_elements(files) AS value LOOP
            -- Gọi function attachment_add cho từng file
            SELECT * INTO attachment_result
            FROM attachment_os_add(
                'organizations',          -- p_target_table
                ARRAY[p_old_org_id] || p_new_orgs,     -- p_target_ids
                file                      -- p_json_input
            );

            -- Kiểm tra kết quả của add_attachment
            IF NOT attachment_result.success THEN
                RAISE EXCEPTION 'Thêm file thất bại: %', attachment_result.message;
            END IF;

            file_urls := file_urls || (file->>'file_url');
        END LOOP;

        -- Gọi function organization_split sau khi lưu tất cả file đính kèm thành công
        SELECT * INTO split_result
        FROM organization_split(
            date_split,
            p_old_org_id,
            p_new_orgs,
            p_employee_movement,
            p_sub_org_movement,
            p_reason,
            p_old_org_active,
            file_urls
        );

        -- Kiểm tra kết quả của organization_split
        IF NOT split_result.status THEN
            RAISE EXCEPTION 'Chia tách tổ chức thất bại: %', split_result.message;
        END IF;

        -- Commit transaction nếu không có lỗi
        RETURN QUERY SELECT TRUE, 'Thêm file đính kèm và chia tách tổ chức thành công';

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaction nếu có lỗi
            RAISE LOG 'Lỗi xảy ra trong quá trình thực thi: %', SQLERRM;
            RETURN QUERY SELECT FALSE, 'Có lỗi xảy ra: ' || SQLERRM;
    END;
END;
$$;


ALTER FUNCTION public.organization_split_with_attachment(date_split date, p_old_org_id integer, p_new_orgs integer[], p_employee_movement jsonb, p_sub_org_movement jsonb, p_reason text, p_old_org_active boolean, files jsonb) OWNER TO postgres;

--
-- Name: organization_update(integer, character varying, character varying, integer, integer, text, text, date, date, integer, boolean, character varying, character varying, integer, text, public.approve_struct_enum, text, date, integer, integer, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organization_update(p_org_id integer, p_name character varying, p_en_name character varying, p_category_id integer, p_districts_id integer, p_address text, p_address_name text, p_effective_date date, p_expired_date date DEFAULT NULL::date, p_parent_org_id integer DEFAULT NULL::integer, p_is_active boolean DEFAULT true, p_phone character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_cost_centers_id integer DEFAULT NULL::integer, p_description text DEFAULT NULL::text, p_approve_struct public.approve_struct_enum DEFAULT NULL::public.approve_struct_enum, p_decision_no text DEFAULT NULL::text, p_decision_date date DEFAULT NULL::date, p_location_id integer DEFAULT NULL::integer, p_general_manager_id integer DEFAULT NULL::integer, p_direct_manager_id integer DEFAULT NULL::integer, files jsonb DEFAULT '[]'::jsonb) RETURNS TABLE(status boolean, message text, org_id integer)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_org RECORD;
    v_old_data RECORD;
    v_row_count INT;
    v_location_id INT;
    tenant_schema TEXT;
    v_log_id INT;
    file JSONB;
    attachment_result RECORD;
    v_attachment_id INT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Khóa bản ghi tổ chức để cập nhật
    SELECT * INTO v_org FROM organizations WHERE id = p_org_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy tổ chức', p_org_id;
        RETURN;
    END IF;

   -- Kiểm tra điều kiện cập nhật
    PERFORM validate_organization_data( p_category_id, p_effective_date, p_parent_org_id, 
    p_general_manager_id, p_direct_manager_id, p_name, p_en_name, p_org_id, p_is_active, p_phone, p_email );


    -- Cập nhật vị trí
    IF p_location_id IS NOT NULL THEN
        v_location_id := p_location_id;
    ELSIF p_districts_id IS NOT NULL AND p_address IS NOT NULL THEN
        INSERT INTO locations (districts_id, address, name)
        VALUES (p_districts_id, p_address, p_address_name)
        RETURNING id INTO v_location_id;
    ELSE
        v_location_id := v_org.location_id;
    END IF;

    -- Lưu dữ liệu cũ
    v_old_data := v_org;

    -- Cập nhật thông tin tổ chức
    UPDATE organizations
    SET 
        name = COALESCE(p_name, name),
        en_name = COALESCE(p_en_name, en_name),
        category_id = COALESCE(p_category_id, category_id),
        parent_org_id = COALESCE(p_parent_org_id, parent_org_id),
        location_id = COALESCE(v_location_id, location_id),
        effective_date = COALESCE(p_effective_date, effective_date),
        expired_date = COALESCE(p_expired_date, expired_date),
        phone = COALESCE(p_phone, phone),
        email = COALESCE(p_email, email),
        description = COALESCE(p_description, description),
        cost_centers_id = COALESCE(p_cost_centers_id, cost_centers_id),
        approve_struct = COALESCE(p_approve_struct, approve_struct),
        decision_no = COALESCE(p_decision_no, decision_no),
        decision_date = COALESCE(p_decision_date, decision_date),
        general_manager_id = COALESCE(p_general_manager_id, general_manager_id),
        direct_manager_id = COALESCE(p_direct_manager_id, direct_manager_id),
        version = version + 1
    WHERE id = p_org_id
    RETURNING * INTO v_org;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count = 0 THEN
        RETURN QUERY SELECT FALSE, 'Không có bản ghi nào được cập nhật', p_org_id;
        RETURN;
    END IF;

    -- Ghi log cập nhật tổ chức
    v_log_id := org_log_insert ( p_org_id, null ,'UPDATE', 'Cập nhật tổ chức', p_description );

    -- Ghi log file đính kèm
    FOR file IN SELECT value FROM jsonb_array_elements(files) AS value LOOP
        SELECT * INTO attachment_result
        FROM attachment_os_add(
            'organizations',
            ARRAY[p_org_id],
            file
        );
        
        v_attachment_id := attachment_result.attachment_id;

        INSERT INTO org_log_attachment (
            log_id, attachment_id
        ) VALUES (
            v_log_id, v_attachment_id
        );
    END LOOP;

    RETURN QUERY SELECT TRUE, 'Cập nhật tổ chức thành công', p_org_id;

EXCEPTION
    WHEN OTHERS THEN
        -- Ghi log lỗi
        RAISE LOG 'Lỗi khi cập nhật tổ chức: %', SQLERRM;

        RETURN QUERY SELECT FALSE, format('Lỗi khi cập nhật tổ chức: %s', SQLERRM), p_org_id;
END;$$;


ALTER FUNCTION public.organization_update(p_org_id integer, p_name character varying, p_en_name character varying, p_category_id integer, p_districts_id integer, p_address text, p_address_name text, p_effective_date date, p_expired_date date, p_parent_org_id integer, p_is_active boolean, p_phone character varying, p_email character varying, p_cost_centers_id integer, p_description text, p_approve_struct public.approve_struct_enum, p_decision_no text, p_decision_date date, p_location_id integer, p_general_manager_id integer, p_direct_manager_id integer, files jsonb) OWNER TO postgres;

--
-- Name: organizations_merge_child(integer[], integer, date, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.organizations_merge_child(merging_org_ids integer[], target_org_id integer, date_merge date DEFAULT now(), file_urls text[] DEFAULT NULL::text[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
    child_count INT := 0;
    org_record RECORD;
    tenant_schema TEXT;
    log_id INT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    -- Cập nhật tất cả các đơn vị con của đơn vị bị sáp nhập
    FOR org_record IN 
        SELECT * FROM organizations 
        WHERE parent_org_id = ANY(merging_org_ids) AND is_active = TRUE
    LOOP
       -- Cập nhật parent_org_id cho từng tổ chức con
        UPDATE organizations
        SET 
            parent_org_id = target_org_id,  
            effective_date = date_merge, 
            version = version + 1
        WHERE id = org_record.id;

        -- Ghi log vào `org_log` dùng SELECT thay vì VALUES
        log_id := org_log_insert (
            org_record.id,
            target_org_id,
            'UPDATED PARENT',
            FORMAT('Chuyển đơn vị con %s vào đơn vị %s', org_record.name, target_org_id),
            FORMAT(
                'Đơn vị %s (ID: %s) đã được chuyển thành đơn vị con của %s (ID: %s).',
                org_record.name, org_record.id, target_org_id, target_org_id
            ) );

        -- Ghi đính kèm file (nếu có)
        PERFORM org_log_attachments_insert(log_id, file_urls);

        -- Tăng biến đếm số đơn vị con đã cập nhật
        child_count := child_count + 1;

    END LOOP;

    -- Trả về số lượng đơn vị con đã cập nhật
    RETURN child_count;
END;
$$;


ALTER FUNCTION public.organizations_merge_child(merging_org_ids integer[], target_org_id integer, date_merge date, file_urls text[]) OWNER TO postgres;

--
-- Name: position_add(integer, integer, integer, text, character varying, boolean, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.position_add(p_job_title_id integer, p_org_id integer, p_staff_allocation integer, p_note text, p_job_position_name character varying, p_is_active boolean DEFAULT true, p_job_desc text DEFAULT NULL::text, p_metadata jsonb DEFAULT NULL::jsonb) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    error_details JSONB := '[]'::JSONB; -- Danh sách lỗi
    tenant_schema TEXT; -- Schema của tenant
    v_position_id INT; -- ID vị trí công việc
BEGIN
    -- Lấy schema của tenant từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Kiểm tra lỗi đầu vào và gom vào JSONB
    error_details := error_details 
        || CASE WHEN p_org_id IS NULL THEN jsonb_build_object('field', 'p_org_id', 'message_error', 'Vui lòng chọn một tổ chức') ELSE '[]'::jsonb END
        || CASE WHEN p_job_title_id IS NULL THEN jsonb_build_object('field', 'p_job_title_id', 'message_error', 'Vui lòng chọn một chức danh công việc') ELSE '[]'::jsonb END
        || CASE WHEN p_staff_allocation IS NULL OR p_staff_allocation < 0 THEN jsonb_build_object('field', 'p_staff_allocation', 'message_error', 'Số lượng nhân viên phân bổ phải là số không âm') ELSE '[]'::jsonb END
        || CASE WHEN p_job_position_name IS NULL OR TRIM(p_job_position_name) = '' THEN jsonb_build_object('field', 'p_job_position_name', 'message_error', 'Tên vị trí công việc không được để trống') ELSE '[]'::jsonb END;

    -- Nếu có lỗi, trả về JSON thông báo lỗi
    IF jsonb_array_length(COALESCE(error_details, '[]'::JSONB)) > 0 THEN
        RETURN jsonb_build_object(
            'code', 400,
            'status', false,
            'message', 'Thêm chức danh công việc vào tổ chức thất bại',
            'errors', error_details
        );
    END IF;

    -- Kiểm tra sự tồn tại của chức danh công việc và tổ chức
    IF NOT EXISTS (SELECT 1 FROM job_titles WHERE id = p_job_title_id) 
       OR NOT EXISTS (SELECT 1 FROM organizations WHERE id = p_org_id) THEN
        RETURN jsonb_build_object(
            'code', 400,
            'status', false,
            'message', 'Thêm chức danh công việc vào tổ chức thất bại',
            'errors', jsonb_build_array(
                CASE WHEN NOT EXISTS (SELECT 1 FROM job_titles WHERE id = p_job_title_id) THEN jsonb_build_object('field', 'p_job_title_id', 'message_error', 'Chức danh công việc không tồn tại') ELSE '[]'::JSONB END,
                CASE WHEN NOT EXISTS (SELECT 1 FROM organizations WHERE id = p_org_id) THEN jsonb_build_object('field', 'p_org_id', 'message_error', 'Tổ chức không tồn tại') ELSE '[]'::JSONB END
            )
        );
    END IF;

    -- Kiểm tra xem mapping đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM job_title_organizations WHERE job_title_id = p_job_title_id AND org_id = p_org_id) THEN
        RETURN jsonb_build_object(
            'code', 409,
            'status', false,
            'message', 'Liên kết chức danh công việc với tổ chức đã tồn tại'
        );
    END IF;

    -- Thêm dữ liệu vào bảng job_title_organizations và lấy ID vừa chèn
    INSERT INTO job_title_organizations (job_title_id, org_id, staff_allocation, note, is_active, job_desc, job_position_name)
    VALUES (p_job_title_id, p_org_id, p_staff_allocation, p_note, p_is_active, p_job_desc, p_job_position_name)
    RETURNING id INTO v_position_id;

    -- Xử lý metadata nếu có
    IF p_metadata IS NOT NULL THEN
        IF jsonb_typeof(p_metadata) = 'array' THEN
            -- Sử dụng truy vấn set-based với jsonb_array_elements để ghi nhiều file cùng lúc
            PERFORM NULL
            FROM (
                SELECT attachment_os_add('job_title_organizations', ARRAY[v_position_id], file_item)
                FROM jsonb_array_elements(p_metadata) AS arr(file_item)
            ) AS t;
        ELSE
            -- Nếu không phải mảng (chỉ có 1 file) thì gọi trực tiếp
            PERFORM attachment_os_add('job_title_organizations', ARRAY[v_position_id], p_metadata);
        END IF;
    END IF;

    -- Trả về kết quả thành công
    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Liên kết chức danh công việc với tổ chức thành công'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code', 500,
            'status', false,
            'message', 'Lỗi máy chủ nội bộ',
            'errors', jsonb_build_array(jsonb_build_object('field', 'general', 'message_error', SQLERRM))
        );
END;
$$;


ALTER FUNCTION public.position_add(p_job_title_id integer, p_org_id integer, p_staff_allocation integer, p_note text, p_job_position_name character varying, p_is_active boolean, p_job_desc text, p_metadata jsonb) OWNER TO postgres;

--
-- Name: position_add_files(integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.position_add_files(p_position_id integer, p_metadata jsonb DEFAULT NULL::jsonb) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    error_details JSONB := '[]'::JSONB; -- Danh sách lỗi
    tenant_schema TEXT; -- Schema của tenant
    v_success BOOLEAN := true; -- Biến theo dõi trạng thái thành công
    v_message TEXT := 'Liên kết chức danh công việc với tổ chức thành công'; -- Thông báo thành công
    file_item RECORD; -- Thêm khai báo biến RECORD
BEGIN

  -- Lấy schema của tenant từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Xử lý metadata nếu có
    IF p_metadata IS NOT NULL THEN
        IF jsonb_typeof(p_metadata) = 'array' THEN
            -- Xử lý từng file trong mảng
            FOR file_item IN SELECT value FROM jsonb_array_elements(p_metadata)
            LOOP
                SELECT success, message INTO v_success, v_message 
                FROM attachment_os_add('job_title_organizations', ARRAY[p_position_id], file_item.value);
                
                IF NOT v_success THEN
                    RAISE EXCEPTION '%', v_message;
                END IF;
            END LOOP;
        ELSE
            -- Xử lý một file
            SELECT success, message INTO v_success, v_message 
            FROM attachment_os_add('job_title_organizations', ARRAY[p_position_id], p_metadata);
            
            IF NOT v_success THEN
                RAISE EXCEPTION '%', v_message;
            END IF;
        END IF;
    END IF;

    -- Trả về kết quả thành công
    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', v_message
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Trả về kết quả lỗi nếu có exception
        RETURN jsonb_build_object(
            'code', 500,
            'status', false,
            'message', 'Lỗi máy chủ nội bộ',
            'errors', jsonb_build_array(jsonb_build_object('field', 'general', 'message_error', SQLERRM))
        );
END;
$$;


ALTER FUNCTION public.position_add_files(p_position_id integer, p_metadata jsonb) OWNER TO postgres;

--
-- Name: position_update(integer, integer, text, boolean, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.position_update(p_id integer, p_staff_allocation integer, p_note text, p_is_active boolean, p_job_desc text, p_metadata jsonb DEFAULT NULL::jsonb) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    error_details JSONB := '[]'::JSONB;
    tenant_schema TEXT;
BEGIN
    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    -- Thiết lập search_path theo schema
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Kiểm tra đầu vào
    IF p_staff_allocation < 0 THEN
        error_details := error_details || jsonb_build_object('field', 'p_staff_allocation', 'message_error', 'Số lượng nhân viên phân bổ phải lớn hơn hoặc bằng 0');
    END IF;

    -- Nếu có lỗi, trả về JSON lỗi
    IF jsonb_array_length(error_details) > 0 THEN
        RETURN jsonb_build_object(
            'code', 400,
            'status', false,
            'message', 'Cập nhật chức danh công việc trong tổ chức thất bại',
            'errors', error_details
        );
    END IF;

    -- Kiểm tra bản ghi tồn tại trước khi cập nhật
    IF NOT EXISTS (
        SELECT 1 FROM job_title_organizations 
        WHERE id = p_id
    ) THEN
        RETURN jsonb_build_object(
            'code', 404,
            'status', false,
            'message', 'Không tìm thấy liên kết giữa chức danh công việc và tổ chức'
        );
    END IF;

    -- Cập nhật bản ghi
    UPDATE job_title_organizations
    SET staff_allocation = p_staff_allocation,
        note = p_note,
        is_active = p_is_active,
        job_desc = p_job_desc
    WHERE id = p_id;

    -- Xử lý metadata nếu có
    IF p_metadata IS NOT NULL THEN
        IF jsonb_typeof(p_metadata) = 'array' THEN
            -- Sử dụng truy vấn set-based với jsonb_array_elements để ghi nhiều file cùng lúc
            PERFORM NULL
            FROM (
                SELECT attachment_os_add('job_title_organizations', ARRAY[p_id], file_item)
                FROM jsonb_array_elements(p_metadata) AS arr(file_item)
            ) AS t;
        ELSE
            -- Nếu không phải mảng (chỉ có 1 file) thì gọi trực tiếp
            PERFORM attachment_os_add('job_title_organizations', ARRAY[p_id], p_metadata);
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Cập nhật liên kết chức danh công việc với tổ chức thành công'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'code', 500,
            'status', false,
            'message', 'Lỗi máy chủ nội bộ',
            'errors', jsonb_build_array(
                jsonb_build_object('field', 'general', 'message_error', SQLERRM)
            )
        );
END;
$$;


ALTER FUNCTION public.position_update(p_id integer, p_staff_allocation integer, p_note text, p_is_active boolean, p_job_desc text, p_metadata jsonb) OWNER TO postgres;

--
-- Name: reward_disciplinary_add(integer, character varying, integer, character varying, character varying, date, date, date, text, character varying, integer, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reward_disciplinary_add(p_emp_id integer, p_decision_no character varying, p_type_reward_id integer, p_issuer character varying, p_issuer_position character varying, p_decision_date date, p_start_date date, p_end_date date, p_note text, p_type character varying, p_form integer, p_reason text, p_decision_authority_name text, p_achievement text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Log bắt đầu
  RAISE NOTICE '🎓 Bắt đầu thêm khen thưởng/kỷ luật cho nhân viên ID %', p_emp_id;

  -- Kiểm tra nhân viên tồn tại
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Nhân viên không tồn tại';
    RETURN;
  END IF;

  -- Gọi validate_reward_disciplinary_input để kiểm tra đầu vào
  PERFORM validate_reward_disciplinary_input(
    p_decision_no, p_issuer, p_issuer_position, p_decision_date, 
    p_start_date, p_end_date, p_type
  );

  -- Thêm bản ghi vào bảng reward_disciplinary
  INSERT INTO reward_disciplinary (
    emp_id, decision_no, type_reward_id, issuer, issuer_position, 
    decision_date, start_date, end_date, note, type, form, 
    reason, decision_authority_name, achievement
  )
  VALUES (
    p_emp_id, p_decision_no, p_type_reward_id, p_issuer, p_issuer_position, 
    p_decision_date, p_start_date, p_end_date, p_note, p_type::public.rewarddisciplinarytype, p_form, 
    p_reason, p_decision_authority_name, p_achievement
  );

  -- Gọi history_employees để ghi log
  PERFORM history_employees(p_emp_id, 'ADD_REWARD_DISCIPLINARY');

  -- Log hoàn tất
  RAISE NOTICE '✅ Đã thêm khen thưởng/kỷ luật và ghi log cho nhân viên ID %', p_emp_id;

  -- Trả về kết quả thành công
  RETURN QUERY SELECT true, 'Tạo khen thưởng/kỷ luật thành công';
EXCEPTION WHEN OTHERS THEN
  -- Bắt lỗi và trả về thông báo lỗi
  RAISE NOTICE 'Lỗi: %', SQLERRM;
  RETURN QUERY SELECT false, SQLERRM;
END;
$$;


ALTER FUNCTION public.reward_disciplinary_add(p_emp_id integer, p_decision_no character varying, p_type_reward_id integer, p_issuer character varying, p_issuer_position character varying, p_decision_date date, p_start_date date, p_end_date date, p_note text, p_type character varying, p_form integer, p_reason text, p_decision_authority_name text, p_achievement text) OWNER TO postgres;

--
-- Name: reward_disciplinary_delete(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reward_disciplinary_delete(p_id integer, p_emp_id integer) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RETURN QUERY SELECT false, 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra bản ghi và nhân viên có tồn tại
  IF NOT EXISTS (SELECT 1 FROM reward_disciplinary WHERE id = p_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy bản ghi khen thưởng/kỷ luật';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy nhân viên';
  END IF;

  -- Xóa dữ liệu
  DELETE FROM reward_disciplinary WHERE id = p_id;

  -- Gọi history_employees để ghi log
  PERFORM history_employees(p_emp_id, 'DELETE_REWARD_DISCIPLINARY');

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Xóa khen thưởng/kỷ luật thành công';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.reward_disciplinary_delete(p_id integer, p_emp_id integer) OWNER TO postgres;

--
-- Name: reward_disciplinary_update(integer, integer, character varying, integer, character varying, character varying, date, date, date, text, character varying, integer, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reward_disciplinary_update(p_id integer, p_emp_id integer, p_decision_no character varying, p_type_reward_id integer, p_issuer character varying, p_issuer_position character varying, p_decision_date date, p_start_date date, p_end_date date, p_note text, p_type character varying, p_form integer, p_reason text, p_decision_authority_name text, p_achievement text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RETURN QUERY SELECT false, 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra bản ghi và nhân viên có tồn tại
  IF NOT EXISTS (SELECT 1 FROM reward_disciplinary WHERE id = p_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy bản ghi khen thưởng/kỷ luật';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Không tìm thấy nhân viên';
  END IF;

  -- Kiểm tra logic ngày tháng
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
    RETURN QUERY SELECT false, 'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc';
  END IF;

  -- Cập nhật dữ liệu
  UPDATE reward_disciplinary
  SET
    emp_id = p_emp_id,
    decision_no = p_decision_no,
    type_reward_id = p_type_reward_id,
    issuer = p_issuer,
    issuer_position = p_issuer_position,
    decision_date = p_decision_date,
    start_date = p_start_date,
    end_date = p_end_date,
    note = p_note,
    type = p_type::public.rewarddisciplinarytype,
    form = p_form,
    reason = p_reason,
    decision_authority_name = p_decision_authority_name,
    achievement = p_achievement
  WHERE id = p_id;

  -- Ghi log lịch sử nhân viên
  PERFORM history_employees(p_emp_id, 'UPDATE_REWARD_DISCIPLINARY');


  -- Log hoàn tất
  RAISE NOTICE '✅ Đã cập nhật khen thưởng/kỷ luật và ghi log cho nhân viên ID %', p_emp_id;

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Cập nhật khen thưởng/kỷ luật thành công';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.reward_disciplinary_update(p_id integer, p_emp_id integer, p_decision_no character varying, p_type_reward_id integer, p_issuer character varying, p_issuer_position character varying, p_decision_date date, p_start_date date, p_end_date date, p_note text, p_type character varying, p_form integer, p_reason text, p_decision_authority_name text, p_achievement text) OWNER TO postgres;

--
-- Name: set_audit_fields(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_audit_fields() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  IF (TG_OP = 'INSERT') THEN
    NEW.created_by := auth.preferred_username();  -- Lấy user_id hiện tại
  END IF;
  NEW.modified_by := auth.preferred_username();
  RETURN NEW;
END;$$;


ALTER FUNCTION public.set_audit_fields() OWNER TO postgres;

--
-- Name: statistic_employee_unit_jobtitle(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.statistic_employee_unit_jobtitle(params jsonb) RETURNS TABLE(organization_name character varying, organization_id integer, org_sort_order integer, org_code character varying, job_title_name character varying, job_title_id integer, job_title_sort_order integer, count bigint, org_parent_name character varying, org_parent_id integer, job_title_organization_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statistic_date     DATE;
    org_ids            INT[];
    job_title_ids      INT[];
BEGIN
    -- Lấy ngày thống kê từ params
    statistic_date := (params->>'statistic_date')::DATE;
 
    -- Parse mảng organization_ids từ JSON params
    SELECT array_agg(elem::INT) INTO org_ids
    FROM jsonb_array_elements_text(COALESCE(params->'organization_ids', '[]')) AS elem;
 
    -- Parse mảng job_title_ids từ JSON params
    SELECT array_agg(elem::INT) INTO job_title_ids
    FROM jsonb_array_elements_text(COALESCE(params->'job_title_ids', '[]')) AS elem;
 
    RETURN QUERY
    WITH RECURSIVE org_tree AS (
 
        -- Đệ quy để xây dựng cây tổ chức từ tổ chức gốc
        SELECT
            o.id,
            o.name,
            o.code,
            o.parent_org_id,
            COALESCE(el.sort_order, 0) AS org_sort_order,
            0 AS level,
            ARRAY[o.id] AS path
        FROM organizations o
        LEFT JOIN enum_lookup el ON o.category_id = el.id
        WHERE o.parent_org_id IS NULL AND o.is_active
 
        UNION ALL
        
        -- Nối các tổ chức con
        SELECT
            c.id,
            c.name,
            c.code,
            c.parent_org_id,
            COALESCE(el.sort_order, 0),
            p.level + 1,
            p.path || c.id
        FROM organizations c
        JOIN org_tree p ON c.parent_org_id = p.id
        LEFT JOIN enum_lookup el ON c.category_id = el.id
        WHERE c.is_active
    ),
 
    filtered_tree AS (
        -- Lọc ra các tổ chức cần thống kê dựa trên org_ids truyền vào
        SELECT * FROM org_tree
        WHERE
            org_ids IS NULL
            OR id = ANY(org_ids)
            OR path && org_ids
    ),
 
    -- Lấy danh sách các tổ chức là cấp cha của org_ids
    leader_orgs AS (
        -- Xác định các tổ chức là cấp cha của các org_ids đầu vào
        SELECT DISTINCT unnest(path[1:array_length(path, 1)-1]) AS org_id
        FROM org_tree
        WHERE id = ANY(org_ids)
    ),
 
    input_combinations AS (
        -- Kết hợp tổ chức và chức danh công việc (từ bảng liên kết job_title_organizations)
        SELECT
            jto.org_id AS organization_id,
            org.name AS organization_name,
            org.code AS org_code,
            org.parent_org_id,
            COALESCE(el.sort_order, 0) AS org_sort_order,
            jto.job_title_id,
            jt.name AS job_title_name,
            COALESCE(jt.sort_order, 0) AS job_title_sort_order,
            jto.job_position_name
        FROM job_title_organizations jto
        JOIN organizations org ON org.id = jto.org_id AND org.is_active
        LEFT JOIN enum_lookup el ON org.category_id = el.id
        JOIN job_titles jt ON jt.id = jto.job_title_id AND jt.is_active
        WHERE jto.is_active
          AND (org_ids IS NULL OR jto.org_id = ANY(org_ids))
          AND (job_title_ids IS NULL OR jto.job_title_id = ANY(job_title_ids))
    ),
 
    pre_filtered_employees AS (
        -- Đếm số lượng nhân viên đang làm việc theo tổ chức + chức danh
        SELECT
            e.organization_id,
            e.job_title_id,
            COUNT(*) AS emp_count
        FROM employees e
        WHERE e.date_join <= statistic_date
          AND (e.date_resign IS NULL OR e.date_resign > statistic_date)
          AND e.last_work_date IS NULL
        GROUP BY e.organization_id, e.job_title_id
    ),
 
    org_total_employees AS (
        -- Tổng số nhân viên theo tổ chức
        SELECT
            e.organization_id,
            COUNT(*) AS emp_count
        FROM klb_dev_uat_core_hr.employee_list_view e
        WHERE e.status in('trial', 'waiting', 'active')
        GROUP BY e.organization_id
    ),
 
    detailed_rows AS (
        -- Thống kê theo từng tổ chức + chức danh công việc
        SELECT
            (ic.organization_name ||
                CASE
                    WHEN lo.org_id IS NOT NULL THEN ' (Ban GĐ)'
                    ELSE ''
                END
            )::VARCHAR AS organization_name,
            ic.organization_id,
            ic.org_sort_order,
            ic.org_code,
            ic.job_title_name,
            ic.job_title_id,
            ic.job_title_sort_order,
            emp.emp_count AS count,
            CASE
              WHEN lo.org_id IS NOT NULL THEN ic.organization_name
              ELSE parent_org.name
            END AS org_parent_name,
            CASE
              WHEN lo.org_id IS NOT NULL THEN ic.organization_id
              ELSE parent_org.id
            END AS org_parent_id,
            ic.job_position_name AS job_title_organization_name,
            NULL::INT AS level,
            NULL::INT[] AS path
        FROM input_combinations ic
        JOIN pre_filtered_employees emp
            ON emp.organization_id = ic.organization_id
            AND emp.job_title_id = ic.job_title_id
        LEFT JOIN organizations parent_org
            ON parent_org.id = ic.parent_org_id
        LEFT JOIN leader_orgs lo
            ON lo.org_id = ic.organization_id
    ),
 
    total_rows AS (
        -- Thống kê tổng nhân sự theo tổ chức (dòng tổng)
        SELECT
            (t.name ||
                CASE
                    WHEN lo.org_id IS NOT NULL THEN ' (Ban GĐ)'
                    ELSE ''
                END
            )::VARCHAR AS organization_name,
            t.id AS organization_id,
            t.org_sort_order,
            t.code AS org_code,
            'Tổng nhân viên' AS job_title_name,
            NULL::INT AS job_title_id,
            -1 AS job_title_sort_order,
            COALESCE(emp.emp_count, 0) AS count,
            CASE
              WHEN lo.org_id IS NOT NULL THEN t.name
              ELSE p.name
            END AS org_parent_name,
            CASE
              WHEN lo.org_id IS NOT NULL THEN t.id
             ELSE t.parent_org_id
            END AS org_parent_id,
            NULL::VARCHAR AS job_title_organization_name,
            t.level,
            t.path
        FROM filtered_tree t
        LEFT JOIN org_total_employees emp ON emp.organization_id = t.id
        LEFT JOIN organizations p ON p.id = t.parent_org_id
        LEFT JOIN leader_orgs lo ON lo.org_id = t.id
    )
 
    -- Gộp detailed_rows và total_rows để trả kết quả
    SELECT
        fr.organization_name,
        fr.organization_id,
        fr.org_sort_order,
        fr.org_code,
        fr.job_title_name,
        fr.job_title_id,
        fr.job_title_sort_order,
        fr.count,
        fr.org_parent_name,
        fr.org_parent_id,
        fr.job_title_organization_name
    FROM (
        SELECT * FROM detailed_rows
        UNION ALL
        SELECT * FROM total_rows
    ) AS fr
    -- Sắp xếp theo cây tổ chức và thứ tự chức danh
    ORDER BY COALESCE(fr.path, ARRAY[fr.organization_id]), fr.job_title_sort_order;
END;
$$;


ALTER FUNCTION public.statistic_employee_unit_jobtitle(params jsonb) OWNER TO postgres;

--
-- Name: unaccent_vi(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unaccent_vi(input text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  s TEXT := lower(input);
BEGIN
  s := replace(s, 'á', 'a');
  s := replace(s, 'à', 'a');
  s := replace(s, 'ả', 'a');
  s := replace(s, 'ã', 'a');
  s := replace(s, 'ạ', 'a');
  s := replace(s, 'â', 'a');
  s := replace(s, 'ầ', 'a');
  s := replace(s, 'ấ', 'a');
  s := replace(s, 'ẩ', 'a');
  s := replace(s, 'ẫ', 'a');
  s := replace(s, 'ậ', 'a');
  s := replace(s, 'ă', 'a');
  s := replace(s, 'ằ', 'a');
  s := replace(s, 'ắ', 'a');
  s := replace(s, 'ẳ', 'a');
  s := replace(s, 'ẵ', 'a');
  s := replace(s, 'ặ', 'a');

  s := replace(s, 'é', 'e');
  s := replace(s, 'è', 'e');
  s := replace(s, 'ẻ', 'e');
  s := replace(s, 'ẽ', 'e');
  s := replace(s, 'ẹ', 'e');
  s := replace(s, 'ê', 'e');
  s := replace(s, 'ề', 'e');
  s := replace(s, 'ế', 'e');
  s := replace(s, 'ể', 'e');
  s := replace(s, 'ễ', 'e');
  s := replace(s, 'ệ', 'e');

  s := replace(s, 'í', 'i');
  s := replace(s, 'ì', 'i');
  s := replace(s, 'ỉ', 'i');
  s := replace(s, 'ĩ', 'i');
  s := replace(s, 'ị', 'i');

  s := replace(s, 'ó', 'o');
  s := replace(s, 'ò', 'o');
  s := replace(s, 'ỏ', 'o');
  s := replace(s, 'õ', 'o');
  s := replace(s, 'ọ', 'o');
  s := replace(s, 'ô', 'o');
  s := replace(s, 'ồ', 'o');
  s := replace(s, 'ố', 'o');
  s := replace(s, 'ổ', 'o');
  s := replace(s, 'ỗ', 'o');
  s := replace(s, 'ộ', 'o');
  s := replace(s, 'ơ', 'o');
  s := replace(s, 'ờ', 'o');
  s := replace(s, 'ớ', 'o');
  s := replace(s, 'ở', 'o');
  s := replace(s, 'ỡ', 'o');
  s := replace(s, 'ợ', 'o');

  s := replace(s, 'ú', 'u');
  s := replace(s, 'ù', 'u');
  s := replace(s, 'ủ', 'u');
  s := replace(s, 'ũ', 'u');
  s := replace(s, 'ụ', 'u');
  s := replace(s, 'ư', 'u');
  s := replace(s, 'ừ', 'u');
  s := replace(s, 'ứ', 'u');
  s := replace(s, 'ử', 'u');
  s := replace(s, 'ữ', 'u');
  s := replace(s, 'ự', 'u');

  s := replace(s, 'ý', 'y');
  s := replace(s, 'ỳ', 'y');
  s := replace(s, 'ỷ', 'y');
  s := replace(s, 'ỹ', 'y');
  s := replace(s, 'ỵ', 'y');

  s := replace(s, 'đ', 'd');

  -- Bỏ tất cả khoảng trắng
  s := replace(s, ' ', '');

  RETURN s;
END;
$$;


ALTER FUNCTION public.unaccent_vi(input text) OWNER TO postgres;

--
-- Name: union_info_update(integer, date, date, text, date, text, text, character varying, text, text, date, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.union_info_update(p_emp_id integer DEFAULT NULL::integer, p_union_start_date date DEFAULT NULL::date, p_union_fee_date date DEFAULT NULL::date, p_union_decision_no text DEFAULT NULL::text, p_union_decision_date date DEFAULT NULL::date, p_union_appointment_no text DEFAULT NULL::text, p_union_position text DEFAULT NULL::text, p_union_organization_name character varying DEFAULT NULL::character varying, p_union_status text DEFAULT NULL::text, p_union_activity text DEFAULT NULL::text, p_party_start_date date DEFAULT NULL::date, p_union_youth_start_date date DEFAULT NULL::date, p_party_official_date date DEFAULT NULL::date) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN
  -- Lấy schema từ JWT claims
  tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
  IF tenant_schema IS NULL THEN
    RAISE EXCEPTION 'Không lấy được schema từ JWT claims';
  END IF;
  PERFORM set_config('search_path', tenant_schema, true);

  -- Kiểm tra nhân viên tồn tại
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
    RETURN QUERY SELECT false, 'Nhân viên không tồn tại';
  END IF;

  -- Cập nhật thông tin công đoàn
  UPDATE employees
  SET
    union_start_date = p_union_start_date,
    union_fee_date = p_union_fee_date,
    union_decision_no = p_union_decision_no,
    union_decision_date = p_union_decision_date,
    union_appointment_no = p_union_appointment_no,
    union_position = p_union_position,
    union_organization_name = p_union_organization_name,
    union_status = p_union_status::public.statusunion,
    union_activity = p_union_activity,
    party_start_date = p_party_start_date,
    union_youth_start_date = p_union_youth_start_date,
    party_official_date = p_party_official_date
  WHERE id = p_emp_id;

  -- Ghi log lịch sử nhân viên
  PERFORM history_employees(p_emp_id, 'UPDATE_UNION_INFO');

  -- Trả kết quả thành công
  RETURN QUERY SELECT true, 'Cập nhật thông tin đoàn, đảng thành công';
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, 'Lỗi: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.union_info_update(p_emp_id integer, p_union_start_date date, p_union_fee_date date, p_union_decision_no text, p_union_decision_date date, p_union_appointment_no text, p_union_position text, p_union_organization_name character varying, p_union_status text, p_union_activity text, p_party_start_date date, p_union_youth_start_date date, p_party_official_date date) OWNER TO postgres;

--
-- Name: update_employee_current_position(integer, integer, integer, integer, integer, text, integer, text, text, date, date, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_employee_current_position(p_employee_id integer, p_new_organization_id integer DEFAULT NULL::integer, p_new_job_title_id integer DEFAULT NULL::integer, p_location_id integer DEFAULT NULL::integer, p_change_type_id integer DEFAULT NULL::integer, p_employee_type text DEFAULT NULL::text, p_manager_id integer DEFAULT NULL::integer, p_decision_signer text DEFAULT NULL::text, p_decision_no text DEFAULT NULL::text, p_decision_sign_date date DEFAULT NULL::date, p_start_date_change date DEFAULT NULL::date, p_end_date_change date DEFAULT NULL::date, p_work_note text DEFAULT NULL::text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_change_type_value TEXT;
    v_current_organization_id INT;
    tenant_schema TEXT;
BEGIN
    -- Hàm cập nhật công việc hiện tại của nhân viên trong quá trình làm việc

     -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    PERFORM set_config('search_path', tenant_schema, true);

    -- 1. Kiểm tra tồn tại nhân viên
    IF NOT check_exists('employees', 'id', p_employee_id) THEN
        RETURN QUERY SELECT FALSE, 'Nhân viên không tồn tại';
        RETURN;
    END IF;

    -- Lấy organization hiện tại (để dùng nếu org_id không được truyền)
    SELECT organization_id INTO v_current_organization_id
    FROM employees WHERE id = p_employee_id;

    -- 2. Kiểm tra chức danh
    IF p_new_job_title_id IS NOT NULL AND NOT check_exists('job_titles', 'id', p_new_job_title_id) THEN
        RETURN QUERY SELECT FALSE, 'Chức danh không tồn tại';
        RETURN;
    END IF;

    -- 3. Kiểm tra đơn vị
    IF p_new_organization_id IS NOT NULL AND NOT check_exists('organizations', 'id', p_new_organization_id) THEN
        RETURN QUERY SELECT FALSE, 'Đơn vị công tác không tồn tại';
        RETURN;
    END IF;

    -- kiểm tra job_title có thuộc tổ chứ không
    IF p_new_job_title_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM job_title_organizations
            WHERE job_title_id = p_new_job_title_id
              AND org_id = COALESCE(p_new_organization_id, v_current_organization_id)
        ) THEN
            RETURN QUERY SELECT FALSE, 'Chức danh không thuộc tổ chức được chọn';
            RETURN;
        END IF;
    END IF;

    -- 4. Kiểm tra địa điểm
    IF p_location_id IS NOT NULL AND NOT check_exists('locations', 'id', p_location_id) THEN
        RETURN QUERY SELECT FALSE, 'Địa điểm làm việc không tồn tại';
        RETURN;
    END IF;

    -- 5. Kiểm tra loại thay đổi
    IF p_change_type_id IS NOT NULL THEN
        IF NOT check_exists('enum_lookup', 'id', p_change_type_id) THEN
            RETURN QUERY SELECT FALSE, 'Loại thay đổi không tồn tại';
            RETURN;
        ELSE
            SELECT value INTO v_change_type_value
            FROM enum_lookup
            WHERE id = p_change_type_id;
        END IF;
    END IF;

    -- 6. Thực hiện cập nhật
    UPDATE employees
    SET 
        organization_id     = COALESCE(p_new_organization_id, organization_id),
        job_title_id        = COALESCE(p_new_job_title_id, job_title_id),
        work_location_id    = COALESCE(p_location_id, work_location_id),
        job_change_type     = COALESCE(v_change_type_value, job_change_type),
        employee_type = COALESCE(p_employee_type::public.employee_types, employee_type),
        manager_id          = COALESCE(p_manager_id, manager_id),
        decision_signer     = COALESCE(p_decision_signer, decision_signer),
        decision_no         = COALESCE(p_decision_no, decision_no),
        decision_sign_date  = COALESCE(p_decision_sign_date, decision_sign_date),
        start_date_change   = COALESCE(p_start_date_change, start_date_change),
        work_note           = COALESCE(p_work_note, work_note),
        end_date_change     = COALESCE(p_end_date_change, end_date_change)
    WHERE id = p_employee_id;

    PERFORM history_employees(p_employee_id, 'UPDATE_POSITION_CURRENT');

    RETURN QUERY SELECT TRUE, 'Cập nhật thành công';
END;$$;


ALTER FUNCTION public.update_employee_current_position(p_employee_id integer, p_new_organization_id integer, p_new_job_title_id integer, p_location_id integer, p_change_type_id integer, p_employee_type text, p_manager_id integer, p_decision_signer text, p_decision_no text, p_decision_sign_date date, p_start_date_change date, p_end_date_change date, p_work_note text) OWNER TO postgres;

--
-- Name: update_report_group_name(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_report_group_name(p_id uuid, p_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE report_group
    SET group_name = p_name
    WHERE id = p_id;
END;
$$;


ALTER FUNCTION public.update_report_group_name(p_id uuid, p_name text) OWNER TO postgres;

--
-- Name: validate_additional_info(integer, integer, integer, integer, public.marital_statuses, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_additional_info(p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
BEGIN
    IF p_hometown_provinces_id IS NOT NULL AND NOT check_exists('provinces', 'id', p_hometown_provinces_id) THEN
        v_errors := add_error(v_errors, 'hometown_provinces_id', 'Tỉnh thành quê quán không tồn tại');
    END IF;

    IF p_ethnicity_id IS NOT NULL AND NOT check_exists('enum_lookup', 'id', p_ethnicity_id) THEN
        v_errors := add_error(v_errors, 'ethnicity_id', 'Dân tộc không tồn tại');
    END IF;

    IF p_nationality_id IS NOT NULL AND NOT check_exists('national', 'id', p_nationality_id) THEN
        v_errors := add_error(v_errors, 'nationality_id', 'Quốc tịch không tồn tại');
    END IF;

    IF p_religion_id IS NOT NULL AND NOT check_exists('enum_lookup', 'id', p_religion_id) THEN
        v_errors := add_error(v_errors, 'religion_id', 'Tôn giáo không tồn tại');
    END IF;

    IF p_marital_status IS NULL THEN
        v_errors := add_error(v_errors, 'marital_status', 'Tình trạng hôn nhân không được để trống');
    END IF;

    IF p_occupation_id IS NOT NULL AND NOT check_exists('enum_lookup', 'id', p_occupation_id) THEN
        v_errors := add_error(v_errors, 'occupation_id', 'Nghề nghiệp không tồn tại');
    END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_additional_info(p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer) OWNER TO postgres;

--
-- Name: validate_address_info(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_address_info(p_permanent_address character varying, p_permanent_district_id integer, p_temporary_district_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_error JSONB;
BEGIN
    v_error := validate_required_text(p_permanent_address, 'permanent_address', 'Địa chỉ thường trú');
    IF v_error IS NOT NULL THEN
        v_errors := add_error(v_errors, 'permanent_address', v_error->>'message');
    END IF;

    IF p_permanent_district_id IS NULL THEN
        v_errors := add_error(v_errors, 'permanent_district_id', 'Quận/huyện thường trú không được để trống');
    ELSIF NOT check_exists('districts', 'id', p_permanent_district_id) THEN
        v_errors := add_error(v_errors, 'permanent_district_id', 'Quận/huyện thường trú không tồn tại');
    END IF;

    -- Kiểm tra quận/huyện tạm trú nếu có
    IF p_temporary_district_id IS NOT NULL THEN
        IF NOT check_exists('districts', 'id', p_temporary_district_id) THEN
            v_errors := add_error(v_errors, 'temporary_district_id', 'Quận/huyện tạm trú không tồn tại');
        END IF;
    END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_address_info(p_permanent_address character varying, p_permanent_district_id integer, p_temporary_district_id integer) OWNER TO postgres;

--
-- Name: validate_banking_info(text, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_banking_info(p_cif_code text, p_bank_account_no character varying, p_bank_name character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_errors JSONB := '[]'::JSONB;
BEGIN
    -- CIF code: nếu khác NULL
    IF p_cif_code IS NOT NULL 
       AND TRIM(p_cif_code) <> '' 
       AND NOT p_cif_code ~ '^[0-9]{3,20}$' THEN
        v_errors := add_error(v_errors, 'cif_code', 'CIF code không hợp lệ');
    END IF;

    -- Bank account no: nếu khác NULL/empty, chỉ gồm 8–30 chữ số
    IF p_bank_account_no IS NOT NULL 
       AND TRIM(p_bank_account_no) <> '' 
       AND NOT p_bank_account_no ~ '^[0-9]{3,20}$' THEN
        v_errors := add_error(v_errors, 'bank_account_no', 'Số tài khoản không hợp lệ');
    END IF;

    -- Bank name: nếu khác NULL/empty, độ dài tối thiểu 3 ký tự, chỉ chứa chữ, số, dấu cách và một số ký tự cho phép (.,-)
    IF p_bank_name IS NOT NULL 
       AND TRIM(p_bank_name) <> '' THEN

        IF char_length(p_bank_name) < 3 THEN
            v_errors := add_error(v_errors, 'bank_name', 'Tên ngân hàng quá ngắn (tối thiểu 3 ký tự)');
        END IF;

    END IF;

    RETURN v_errors;
END;
$_$;


ALTER FUNCTION public.validate_banking_info(p_cif_code text, p_bank_account_no character varying, p_bank_name character varying) OWNER TO postgres;

--
-- Name: validate_basic_info(text, text, public.gender, date, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_basic_info(p_last_name text, p_first_name text, p_gender public.gender, p_dob date, p_email_internal text, p_phone text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_error JSONB;
BEGIN
    v_error := validate_required_text(p_last_name, 'last_name', 'Tên');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'last_name', v_error->>'message'); END IF;

    v_error := validate_required_text(p_first_name, 'first_name', 'Họ');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'first_name', v_error->>'message'); END IF;

    IF p_gender IS NULL THEN
        v_errors := add_error(v_errors, 'gender', 'Giới tính không được để trống');
    END IF;

    IF p_dob IS NULL THEN
        v_errors := add_error(v_errors, 'dob', 'Ngày sinh không được để trống');
    ELSIF AGE(CURRENT_DATE, p_dob) < INTERVAL '18 years' THEN
        v_errors := add_error(v_errors, 'dob', 'Người lao động phải đủ 18 tuổi');
    END IF;

    v_error := validate_email(p_email_internal, 'email_internal', 'Email nội bộ');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'email_internal', v_error->>'message'); END IF;

    v_error := validate_phone(p_phone, 'phone', 'Số điện thoại');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'phone', v_error->>'message'); END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_basic_info(p_last_name text, p_first_name text, p_gender public.gender, p_dob date, p_email_internal text, p_phone text) OWNER TO postgres;

--
-- Name: validate_basic_info(text, text, public.gender, date, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_basic_info(p_last_name text, p_first_name text, p_gender public.gender, p_dob date, p_identity_no text, p_email_internal text, p_phone text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_error JSONB;
BEGIN
    v_error := validate_required_text(p_last_name, 'last_name', 'Tên');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'last_name', v_error->>'message'); END IF;

    v_error := validate_required_text(p_first_name, 'first_name', 'Họ');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'first_name', v_error->>'message'); END IF;

    IF p_gender IS NULL THEN
        v_errors := add_error(v_errors, 'gender', 'Giới tính không được để trống');
    END IF;

    IF p_dob IS NULL THEN
        v_errors := add_error(v_errors, 'dob', 'Ngày sinh không được để trống');
    ELSIF AGE(CURRENT_DATE, p_dob) < INTERVAL '18 years' THEN
        v_errors := add_error(v_errors, 'dob', 'Người lao động phải đủ 18 tuổi');
    END IF;

    v_error := validate_email(p_email_internal, 'email_internal', 'Email nội bộ');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'email_internal', v_error->>'message'); END IF;

    v_error := validate_phone(p_phone, 'phone', 'Số điện thoại');
    IF v_error IS NOT NULL THEN v_errors := add_error(v_errors, 'phone', v_error->>'message'); END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_basic_info(p_last_name text, p_first_name text, p_gender public.gender, p_dob date, p_identity_no text, p_email_internal text, p_phone text) OWNER TO postgres;

--
-- Name: validate_certificate_input(integer, character varying, character varying, character varying, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_certificate_input(p_type_id integer, p_cert_no character varying, p_name character varying, p_issued_by character varying, p_date_issue date, p_expired_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
  -- Kiểm tra các trường bắt buộc
  IF p_type_id IS NULL THEN
    RAISE EXCEPTION 'Trường "loại chứng chỉ" không được để trống';
  END IF;

  IF p_cert_no IS NULL THEN
    RAISE EXCEPTION 'Trường "mã số chứng chỉ" không được để trống';
  END IF;

  IF p_name IS NULL THEN
    RAISE EXCEPTION 'Trường "tên chứng chỉ" không được để trống';
  END IF;

  IF p_issued_by IS NULL THEN
    RAISE EXCEPTION 'Trường "nơi cấp" không được để trống';
  END IF;

  IF p_date_issue IS NULL THEN
    RAISE EXCEPTION 'Trường "ngày cấp" không được để trống';
  END IF;

  -- Kiểm tra logic ngày tháng
  IF p_expired_date IS NOT NULL THEN 
    IF p_expired_date < p_date_issue THEN
      RAISE EXCEPTION 'Ngày hết hạn phải sau hoặc bằng ngày cấp';
    END IF;
  END IF;
END;$$;


ALTER FUNCTION public.validate_certificate_input(p_type_id integer, p_cert_no character varying, p_name character varying, p_issued_by character varying, p_date_issue date, p_expired_date date) OWNER TO postgres;

--
-- Name: validate_contact_info(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_contact_info(p_email_external text, p_secondary_phone text, p_home_phone text, p_company_phone text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_errors JSONB := '[]'::JSONB;
BEGIN
    IF p_email_external IS NOT NULL AND TRIM(p_email_external) != '' AND NOT p_email_external ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        v_errors := add_error(v_errors, 'email_external', 'Email cá nhân không hợp lệ');
    END IF;

    IF p_secondary_phone IS NOT NULL AND TRIM(p_secondary_phone) != '' AND NOT p_secondary_phone ~ '^[0-9]{10,11}$' THEN
        v_errors := add_error(v_errors, 'secondary_phone', 'Số điện thoại phụ không hợp lệ');
    END IF;

    IF p_home_phone IS NOT NULL AND TRIM(p_home_phone) != '' AND NOT p_home_phone ~ '^[0-9]{10,11}$' THEN
        v_errors := add_error(v_errors, 'home_phone', 'Số điện thoại nhà không hợp lệ');
    END IF;

    IF p_company_phone IS NOT NULL AND TRIM(p_company_phone) != '' AND NOT p_company_phone ~ '^[0-9]{10,11}$' THEN
        v_errors := add_error(v_errors, 'company_phone', 'Số điện thoại công ty không hợp lệ');
    END IF;

    RETURN v_errors;
END;
$_$;


ALTER FUNCTION public.validate_contact_info(p_email_external text, p_secondary_phone text, p_home_phone text, p_company_phone text) OWNER TO postgres;

--
-- Name: validate_create_job_title(character varying, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_create_job_title(p_code character varying, p_name character varying, p_group_id integer, p_grade_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN
    -- Kiểm tra không nhập mã chức danh
    IF p_code IS NULL OR LENGTH(TRIM(p_code)) = 0 THEN
        RAISE EXCEPTION 'Vui lòng nhập mã chức danh.';
    END IF;

-- Kiểm tra độ dài mã chức danh
    IF LENGTH(TRIM(p_code)) > 50 THEN
        RAISE EXCEPTION 'Mã chức danh không được vượt quá 50 ký tự.';
    END IF;

    -- Kiểm tra định dạng mã chức danh (chỉ cho phép chữ cái, số, dấu gạch dưới, dấu gạch ngang)
    IF TRIM(p_code) !~ '^[a-zA-Z0-9_-]+$' THEN
        RAISE EXCEPTION 'Mã chức danh không hợp lệ.';
    END IF;

    -- Kiểm tra khoảng trắng không hợp lệ ở giữa mã chức danh
    IF p_code ~ '\s' THEN
        RAISE EXCEPTION 'Mã chức danh không được chứa khoảng trắng.';
    END IF;

    -- Kiểm tra trùng mã chức danh
    IF EXISTS (SELECT 1 FROM job_titles WHERE code = TRIM(p_code)) THEN
        RAISE EXCEPTION 'Mã chức danh "%" đã tồn tại.', p_code;
    END IF;

    -- Kiểm tra không nhập tên chức danh
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Vui lòng nhập tên chức danh.';
    END IF;

    -- Kiểm tra không nhập group_id
    IF p_group_id IS NULL THEN
        RAISE EXCEPTION 'Vui lòng chọn nhóm chức danh.';
    END IF;

    -- Kiểm tra tồn tại của group_id
    IF NOT EXISTS (SELECT 1 FROM job_groups WHERE id = p_group_id) THEN
        RAISE EXCEPTION 'Nhóm chức danh với ID "%" không tồn tại.', p_group_id;
    END IF;

    -- Kiểm tra tồn tại của grade_id nếu có truyền vào
    IF p_grade_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM job_grades WHERE id = p_grade_id) THEN
        RAISE EXCEPTION 'Ngạch chức danh với ID "%" không tồn tại.', p_grade_id;
    END IF;

    -- Log validate thành công
    RAISE LOG 'Xác thực thành công chức danh: mã=%s, tên=%s', p_code, p_name;
END;
$_$;


ALTER FUNCTION public.validate_create_job_title(p_code character varying, p_name character varying, p_group_id integer, p_grade_id integer) OWNER TO postgres;

--
-- Name: validate_date(date, text, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_date(p_value date, p_field text, p_field_name text, p_allow_future boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_value IS NULL THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không được để trống');
    ELSIF NOT p_allow_future AND p_value > CURRENT_DATE THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không được lớn hơn ngày hiện tại');
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.validate_date(p_value date, p_field text, p_field_name text, p_allow_future boolean) OWNER TO postgres;

--
-- Name: validate_degree_input(character varying, character varying, character varying, character varying, character varying, character varying, date, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_degree_input(p_type character varying, p_degree_no character varying, p_academic character varying, p_institution character varying, p_major character varying, p_education_mode character varying, p_start_date date, p_end_date date, p_graduation_year date) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Kiểm tra các trường bắt buộc
  IF p_type IS NULL THEN
    RAISE EXCEPTION 'Trường "loại bằng cấp" không được để trống';
  END IF;

  IF p_degree_no IS NULL THEN
    RAISE EXCEPTION 'Trường "mã số bằng cấp" không được để trống';
  END IF;

  IF p_academic IS NULL THEN
    RAISE EXCEPTION 'Trường "học vị" không được để trống';
  END IF;

  IF p_institution IS NULL THEN
    RAISE EXCEPTION 'Trường "trường cấp bằng" không được để trống';
  END IF;

  IF p_major IS NULL THEN
    RAISE EXCEPTION 'Trường "chuyên ngành" không được để trống';
  END IF;

  IF p_education_mode IS NULL THEN
    RAISE EXCEPTION 'Trường "hình thức đào tạo" không được để trống';
  END IF;

  IF p_graduation_year IS NULL THEN
    RAISE EXCEPTION 'Trường "năm tốt nghiệp" không được để trống';
  END IF;

  -- Kiểm tra logic thời gian
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
    RAISE EXCEPTION 'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc';
  END IF;

  IF p_end_date IS NOT NULL AND p_graduation_year IS NOT NULL AND p_end_date > p_graduation_year THEN
    RAISE EXCEPTION 'Ngày kết thúc phải nhỏ hơn hoặc bằng năm tốt nghiệp';
  END IF;
END;
$$;


ALTER FUNCTION public.validate_degree_input(p_type character varying, p_degree_no character varying, p_academic character varying, p_institution character varying, p_major character varying, p_education_mode character varying, p_start_date date, p_end_date date, p_graduation_year date) OWNER TO postgres;

--
-- Name: validate_dissolve_organization(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_dissolve_organization(p_org_id integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    tenant_schema TEXT;
    v_employee_count INT;
    v_assignment_count INT;
    v_child_org_count INT;
    v_org RECORD;
BEGIN
    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Kiểm tra nếu đơn vị tồn tại
    SELECT * INTO v_org FROM organizations WHERE id = p_org_id;
    IF NOT FOUND THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Tổ chức không tồn tại', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra nếu đơn vị đang hoạt động
    IF v_org.is_active = FALSE THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị không còn hoạt động', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra xem đơn vị có nhân sự chính thức hay không
    SELECT COUNT(*) INTO v_employee_count FROM employees WHERE organization_id = p_org_id;
    IF v_employee_count > 0 THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị còn nhân viên chính thức', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra xem đơn vị có nhân sự đang kiêm nhiệm hay không
    SELECT COUNT(*) INTO v_assignment_count FROM job_assignments WHERE org_id = p_org_id AND is_active = TRUE;
    IF v_assignment_count > 0 THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị còn nhân viên kiêm nhiệm', 'org_id', p_org_id);
    END IF;

    -- Kiểm tra xem đơn vị có đơn vị con còn hoạt động hay không
    SELECT COUNT(*) INTO v_child_org_count FROM organizations WHERE parent_org_id = p_org_id AND is_active = TRUE;
    IF v_child_org_count > 0 THEN
        RETURN json_build_object('status', 'FAIL', 'message', 'Không thể giải thể vì đơn vị còn đơn vị con đang hoạt động', 'org_id', p_org_id);
    END IF;

    -- Nếu tất cả điều kiện đều đạt, trả về thành công
    RETURN json_build_object('status', 'SUCCESS', 'message', 'Có thể giải thể tổ chức', 'org_id', p_org_id);
END;
$$;


ALTER FUNCTION public.validate_dissolve_organization(p_org_id integer) OWNER TO postgres;

--
-- Name: validate_education_info(public.education_level, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_education_info(p_education_level public.education_level, p_en_cert_id integer, p_it_cert_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
BEGIN
    IF p_education_level IS NULL THEN
        v_errors := add_error(v_errors, 'education_level', 'Trình độ học vấn không được để trống');
    END IF;

    IF p_en_cert_id IS NOT NULL AND NOT check_exists('enum_lookup', 'id', p_en_cert_id) THEN
        v_errors := add_error(v_errors, 'en_cert_id', 'Chứng chỉ tiếng Anh không tồn tại');
    END IF;

    IF p_it_cert_id IS NOT NULL AND NOT check_exists('enum_lookup', 'id', p_it_cert_id) THEN
        v_errors := add_error(v_errors, 'it_cert_id', 'Chứng chỉ tin học không tồn tại');
    END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_education_info(p_education_level public.education_level, p_en_cert_id integer, p_it_cert_id integer) OWNER TO postgres;

--
-- Name: validate_email(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_email(p_value text, p_field text, p_field_name text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF p_value IS NULL OR TRIM(p_value) = '' THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không được để trống');
    ELSIF NOT p_value ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không hợp lệ');
    END IF;
    RETURN NULL;
END;
$_$;


ALTER FUNCTION public.validate_email(p_value text, p_field text, p_field_name text) OWNER TO postgres;

--
-- Name: validate_emp_and_identity(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_emp_and_identity(p_emp_code text DEFAULT NULL::text, p_identity_no text DEFAULT NULL::text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT claims
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    PERFORM set_config('search_path', tenant_schema, true);

    IF p_emp_code IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM employees WHERE emp_code = p_emp_code) THEN
            RETURN QUERY SELECT FALSE, format('Mã nhân viên "%s" đã tồn tại.', p_emp_code);
            RETURN;
        END IF;
    END IF;

    IF p_identity_no IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM employees WHERE identity_no = p_identity_no) THEN
            RETURN QUERY SELECT FALSE, format('CCCD/CMND "%s" đã tồn tại.', p_identity_no);
            RETURN;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, 'Dữ liệu hợp lệ.';
END;
$$;


ALTER FUNCTION public.validate_emp_and_identity(p_emp_code text, p_identity_no text) OWNER TO postgres;

--
-- Name: validate_empl_manager(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_empl_manager(p_manager_id integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors       JSONB := '[]'::JSONB;
    v_manager_type INTEGER;
BEGIN
    -- Nếu không có manager_id thì bỏ qua luôn
    IF p_manager_id IS NULL THEN
        RETURN v_errors;
    END IF;

    -- Lấy luôn kiểu (enum->text->int); nếu không tìm thấy thì NOT FOUND = true
    SELECT (employee_type::TEXT)::INTEGER
      INTO v_manager_type
    FROM employees
    WHERE id = p_manager_id;

    IF NOT FOUND THEN
        v_errors := add_error(
            v_errors,
            'manager_id',
            'Người quản lý không tồn tại trong hệ thống'
        );
    ELSIF v_manager_type NOT IN (1, 2) THEN
        v_errors := add_error(
            v_errors,
            'manager_id',
            'Người quản lý phải là cấp phó hoặc trưởng bộ phận'
        );
    END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_empl_manager(p_manager_id integer) OWNER TO postgres;

--
-- Name: validate_employee_add(character varying, character varying, character varying, integer, character varying, date, date, integer, integer, date, date, date, integer, date, integer, integer, public.marital_statuses, character varying, integer, character varying, integer, integer, integer, character varying, character varying, character varying, character varying, public.gender, public.education_level, public.employee_types, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_employee_add(p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_nationality_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_job_title_id integer, p_date_join date, p_start_date_change date, p_end_date_change date, p_change_type_id integer, p_dob date, p_ethnicity_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_organization_id integer, p_work_location_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_gender public.gender, p_education_level public.education_level, p_employee_type public.employee_types, p_manager_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_err    JSONB;
BEGIN
    -- 1. Basic info
    v_errors := v_errors 
        || COALESCE(
           validate_basic_info(
             p_last_name, p_first_name, p_gender, p_dob,
             p_email_internal, p_phone
           ), '[]'::JSONB);

    -- 2. Additional info
    v_errors := v_errors
        || COALESCE(
           validate_additional_info(
             NULL, p_ethnicity_id, p_nationality_id,
             p_religion_id, p_marital_status, NULL
           ), '[]'::JSONB);

    -- 3. Identity info
    v_errors := v_errors
        || COALESCE(
           validate_identity_info(
             p_identity_no, p_date_issue, p_date_identity_expiry,
             p_place_issue_id, NULL
           ), '[]'::JSONB);

    -- 4. Education info
    v_errors := v_errors
        || COALESCE(
           validate_education_info(p_education_level, NULL, NULL),
           '[]'::JSONB);

    -- 5. Contact info
    v_errors := v_errors
        || COALESCE(
           validate_contact_info(p_email_external, p_secondary_phone, NULL, NULL),
           '[]'::JSONB);

    -- 6. Job position & join date
    v_err := validate_job_position(
               p_job_title_id, p_organization_id,
               p_work_location_id, p_date_join
             );
    IF v_err IS NOT NULL THEN
        v_errors := v_errors || v_err;
    END IF;

    -- 7. Address info
    v_errors := v_errors
        || COALESCE(
           validate_address_info(
             p_permanent_address, p_permanent_district_id,
             p_temporary_district_id
           ), '[]'::JSONB);

    -- 8. Manager
    v_errors := v_errors
        || COALESCE(validate_empl_manager(p_manager_id), '[]'::JSONB);

    -- 9. Ngày thay đổi hợp lệ
    IF p_start_date_change IS NOT NULL AND p_end_date_change IS NOT NULL 
       AND p_end_date_change < p_start_date_change
    THEN
        v_errors := add_error(
            v_errors,
            'end_date_change',
            'Ngày kết thúc thay đổi phải sau ngày bắt đầu thay đổi'
        );
    END IF;

    -- 10. Kiểm tra change_type
    IF p_change_type_id IS NULL
       OR NOT check_exists('enum_lookup','id',p_change_type_id)
    THEN
        v_errors := add_error(
            v_errors,
            'change_type_id',
            'Loại thay đổi không tồn tại'
        );
    END IF;

    -- Kết quả chung
    IF jsonb_array_length(v_errors) > 0 THEN
        RETURN jsonb_build_object(
            'code',   400,
            'status', false,
            'message','Dữ liệu không hợp lệ',
            'errors', v_errors
        );
    END IF;

    RETURN jsonb_build_object(
        'code',   200,
        'status', true,
        'message','Dữ liệu hợp lệ'
    );
END;
$$;


ALTER FUNCTION public.validate_employee_add(p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_nationality_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_job_title_id integer, p_date_join date, p_start_date_change date, p_end_date_change date, p_change_type_id integer, p_dob date, p_ethnicity_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_organization_id integer, p_work_location_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_gender public.gender, p_education_level public.education_level, p_employee_type public.employee_types, p_manager_id integer) OWNER TO postgres;

--
-- Name: validate_employee_position_update(integer, integer, integer, integer, integer, character varying, character varying, date, date, date, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_employee_position_update(p_emp_id integer, p_job_title_id integer, p_organization_id integer, p_change_type_id integer, p_location_id integer, p_decision_no character varying, p_decision_signer character varying, p_decision_sign_date date, p_start_date_change date, p_end_date_change date, p_manager_id integer, p_reason text, p_work_note text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors   JSONB := '[]'::JSONB;
BEGIN
    -- 1. Kiểm tra tồn tại nhân viên
    IF NOT check_exists('employees', 'id', p_emp_id) THEN
        v_errors := add_error(v_errors, 'emp_id', 'Nhân viên không tồn tại');
    END IF;

    -- 2. Kiểm tra chức danh
    IF NOT check_exists('job_titles', 'id', p_job_title_id) THEN
        v_errors := add_error(v_errors, 'job_title_id', 'Chức danh không tồn tại');
    END IF;

    -- 3. Kiểm tra đơn vị
    IF NOT check_exists('organizations', 'id', p_organization_id) THEN
        v_errors := add_error(v_errors, 'organization_id', 'Đơn vị công tác không tồn tại');
    END IF;

    -- 4. Kiểm tra địa điểm
    IF NOT check_exists('locations', 'id', p_location_id) THEN
        v_errors := add_error(v_errors, 'location_id', 'Địa điểm làm việc không tồn tại');
    END IF;

    -- Kiểm tra ngày bắt đầu và ngày kết thúc
    IF p_end_date_change IS NOT NULL THEN
        IF p_end_date_change < p_start_date_change THEN
            v_errors := add_error(v_errors, 'date_issue', 'Ngày kết thúc thay đổi phải sau ngày bắt đầu thay đổi');
        END IF;
    END IF;

    -- 5. Kiểm tra change_type và lấy value
    IF NOT check_exists('enum_lookup', 'id', p_change_type_id) THEN
        v_errors := add_error(v_errors, 'change_type_id', 'Loại thay đổi không tồn tại');
    END IF;

    -- 6. Kiểm tra manager
    v_errors := v_errors || validate_empl_manager(p_manager_id);

    -- 7. Kiểm tra combo job_title + org
    IF p_job_title_id IS NOT NULL AND p_organization_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM job_title_organizations
            WHERE job_title_id = p_job_title_id
              AND org_id       = p_organization_id
        ) THEN
            v_errors := add_error(v_errors, 'job_title_id & organization_id', 'Vị trí công việc không tồn tại');
        END IF;
    END IF;

    -- Trả về kết quả
    IF jsonb_array_length(v_errors) > 0 THEN
        RETURN jsonb_build_object(
            'code',   400,
            'status', false,
            'message','Dữ liệu không hợp lệ',
            'errors', v_errors
        );
    END IF;

    RETURN jsonb_build_object(
        'code',   200,
        'status', true,
        'message','Dữ liệu hợp lệ'
    );
END;
$$;


ALTER FUNCTION public.validate_employee_position_update(p_emp_id integer, p_job_title_id integer, p_organization_id integer, p_change_type_id integer, p_location_id integer, p_decision_no character varying, p_decision_signer character varying, p_decision_sign_date date, p_start_date_change date, p_end_date_change date, p_manager_id integer, p_reason text, p_work_note text) OWNER TO postgres;

--
-- Name: validate_employee_update(integer, character varying, character varying, character varying, public.gender, date, integer, integer, integer, integer, public.marital_statuses, integer, character varying, date, date, integer, character varying, date, text, public.education_level, character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, text, character varying, character varying, integer, character varying, integer, character varying, integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_employee_update(p_id integer, p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_gender public.gender, p_dob date, p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no character varying, p_old_date_issue date, p_old_place_issue_id text, p_education_level public.education_level, p_degree_type character varying, p_institution character varying, p_major character varying, p_en_cert_id integer, p_it_cert_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_home_phone character varying, p_company_phone character varying, p_cif_code text, p_bank_account_no character varying, p_bank_name character varying, p_manager_id integer, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_date_join date) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_error_details JSONB := '[]'::JSONB;
    v_current_employee RECORD;
    v_full_name VARCHAR(100);
    v_date_err JSONB;
BEGIN
    -- Get current employee data
    SELECT * INTO v_current_employee 
    FROM employees 
    WHERE id = p_id;

    IF NOT FOUND THEN
        v_error_details := add_error(v_error_details, 'id', 'Nhân viên không tồn tại trong hệ thống');
    END IF;

    -- Validate basic info
    v_error_details := v_error_details || validate_basic_info(
        p_last_name,
        p_first_name,
        p_gender,
        p_dob,
        p_email_internal,
        p_phone
    );

    -- Validate additional info
    v_error_details := v_error_details || validate_additional_info(
        p_hometown_provinces_id,
        p_ethnicity_id,
        p_nationality_id,
        p_religion_id,
        p_marital_status,
        p_occupation_id
    );

    -- Validate identity info
    v_error_details := v_error_details || validate_identity_info(
        p_identity_no,
        p_date_issue,
        p_date_identity_expiry,
        p_place_issue_id,
        p_old_identity_no,
        p_id,
        p_old_date_issue,
        p_old_place_issue_id
    );

    -- Validate education info
    v_error_details := v_error_details || validate_education_info(
        p_education_level,
        p_en_cert_id,
        p_it_cert_id
    );

    -- Validate contact info
    v_error_details := v_error_details || validate_contact_info(
        p_email_external,
        p_secondary_phone,
        p_home_phone,
        p_company_phone
    );

    -- Validate banking info
    v_error_details := v_error_details || validate_banking_info(
        p_cif_code,
        p_bank_account_no,
        p_bank_name
    );

    -- Validate manager
    v_error_details := v_error_details || validate_empl_manager(p_manager_id);

    -- Validate address info
    v_error_details := v_error_details || validate_address_info(
        p_permanent_address,
        p_permanent_district_id,
        p_temporary_district_id
    );

    v_date_err := validate_date(p_date_join, 'date_join', 'Ngày vào làm', TRUE);
    IF v_date_err IS NOT NULL THEN
        v_error_details := v_error_details || v_date_err;
    END IF;

    -- Return validation result
    IF jsonb_array_length(v_error_details) > 0 THEN
        RETURN jsonb_build_object(
            'code', 400,
            'status', false,
            'message', 'Dữ liệu không hợp lệ',
            'errors', v_error_details
        );
    END IF;

    RETURN jsonb_build_object(
        'code', 200,
        'status', true,
        'message', 'Dữ liệu hợp lệ'
    );
END;
$$;


ALTER FUNCTION public.validate_employee_update(p_id integer, p_last_name character varying, p_middle_name character varying, p_first_name character varying, p_gender public.gender, p_dob date, p_hometown_provinces_id integer, p_ethnicity_id integer, p_nationality_id integer, p_religion_id integer, p_marital_status public.marital_statuses, p_occupation_id integer, p_identity_no character varying, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no character varying, p_old_date_issue date, p_old_place_issue_id text, p_education_level public.education_level, p_degree_type character varying, p_institution character varying, p_major character varying, p_en_cert_id integer, p_it_cert_id integer, p_email_internal character varying, p_email_external character varying, p_phone character varying, p_secondary_phone character varying, p_home_phone character varying, p_company_phone character varying, p_cif_code text, p_bank_account_no character varying, p_bank_name character varying, p_manager_id integer, p_permanent_address character varying, p_permanent_district_id integer, p_temporary_address character varying, p_temporary_district_id integer, p_date_join date) OWNER TO postgres;

--
-- Name: validate_external_experience_input(character varying, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_external_experience_input(p_company_name character varying, p_start_date date, p_end_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Kiểm tra các trường bắt buộc
  IF p_company_name IS NULL THEN
    RAISE EXCEPTION 'Trường "tên công ty" không được để trống';
  END IF;

  IF p_start_date IS NULL THEN
    RAISE EXCEPTION 'Trường "ngày bắt đầu làm việc" không được để trống';
  END IF;

  -- Kiểm tra logic ngày tháng
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
    RAISE EXCEPTION 'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc';
  END IF;
END;
$$;


ALTER FUNCTION public.validate_external_experience_input(p_company_name character varying, p_start_date date, p_end_date date) OWNER TO postgres;

--
-- Name: validate_family_dependent_input(text, character varying, integer, text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_family_dependent_input(p_full_name text, p_gender character varying, p_dob integer, p_address text, p_identity_no text, p_identity_type text, p_occupation text, p_relationship_type_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
  -- Kiểm tra các trường bắt buộc
  IF p_full_name IS NULL OR TRIM(p_full_name) = '' THEN
    RAISE EXCEPTION 'Trường "Họ và tên" không được để trống';
  END IF;

  IF p_gender IS NULL OR TRIM(p_gender) = '' THEN
    RAISE EXCEPTION 'Trường "Giới tính" không được để trống';
  END IF;

  IF p_dob IS NULL THEN
    RAISE EXCEPTION 'Trường "Ngày sinh" không được để trống';
  END IF;

  IF p_address IS NULL OR TRIM(p_address) = '' THEN
    RAISE EXCEPTION 'Trường "Địa chỉ" không được để trống';
  END IF;


  IF p_occupation IS NULL OR TRIM(p_occupation) = '' THEN
    RAISE EXCEPTION 'Trường "Nghề nghiệp" không được để trống';
  END IF;

  IF p_relationship_type_id IS NULL THEN
    RAISE EXCEPTION 'Trường "Loại quan hệ" không được để trống';
  END IF;
END;$$;


ALTER FUNCTION public.validate_family_dependent_input(p_full_name text, p_gender character varying, p_dob integer, p_address text, p_identity_no text, p_identity_type text, p_occupation text, p_relationship_type_id integer) OWNER TO postgres;

--
-- Name: validate_identity_info(text, date, date, integer, text, integer, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_identity_info(p_identity_no text, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no text, p_exclude_id integer DEFAULT NULL::integer, p_old_date_issue date DEFAULT NULL::date, p_old_place_issue_id text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_error JSONB;
    v_existing_emp_code TEXT;
BEGIN
    -- Required and uniqueness checks for new identity number
    v_error := validate_required_text(p_identity_no, 'identity_no', 'Số CCCD');
    IF v_error IS NOT NULL THEN
        v_errors := add_error(v_errors, 'identity_no', v_error->>'message');
    ELSE
        -- Numeric format check
        IF p_identity_no !~ '^[0-9]+$' THEN
            v_errors := add_error(v_errors, 'identity_no', 'Số CCCD chỉ được gồm các chữ số 0-9');
        END IF;
        -- Length check (12 chữ số cho CCCD)
        IF length(p_identity_no) != 12 THEN
            v_errors := add_error(v_errors, 'identity_no', 'Số CCCD phải đúng 12 chữ số');
        END IF;
        -- Uniqueness check
        IF NOT check_unique('employees', 'identity_no', p_identity_no, p_exclude_id) THEN
            -- Lấy emp_code của nhân viên đã tồn tại
            SELECT emp_code INTO v_existing_emp_code
            FROM employees
            WHERE identity_no = p_identity_no
            AND (p_exclude_id IS NULL OR id != p_exclude_id)
            LIMIT 1;
            v_errors := add_error(v_errors, 'identity_no', format('Số CCCD đã tồn tại trong hệ thống với mã nhân viên: %s', v_existing_emp_code));
        END IF;
    END IF;

    -- Issue date checks
    v_error := validate_date(p_date_issue, 'date_issue', 'Ngày cấp CCCD');
    IF v_error IS NOT NULL THEN
        v_errors := add_error(v_errors, 'date_issue', v_error->>'message');
    ELSE
        -- Date must not be in the future
        IF p_date_issue > CURRENT_DATE THEN
            v_errors := add_error(v_errors, 'date_issue', 'Ngày cấp CCCD phải là ngày trong quá khứ');
        END IF;
    END IF;

    -- Expiry date must be today or in the future
    IF p_date_identity_expiry IS NOT NULL AND p_date_identity_expiry < CURRENT_DATE THEN
        v_errors := add_error(v_errors, 'date_identity_expiry', 'Ngày hết hạn CCCD không được nhỏ hơn ngày hiện tại');
    END IF;

    -- Place of issue checks
    IF p_place_issue_id IS NULL THEN
        v_errors := add_error(v_errors, 'place_issue_id', 'Nơi cấp CCCD không được để trống');
    ELSIF NOT check_exists('enum_lookup', 'id', p_place_issue_id) THEN
        v_errors := add_error(v_errors, 'place_issue_id', 'Nơi cấp CCCD không tồn tại');
    END IF;

    -- Old identity number (CMT) optional checks
    IF p_old_identity_no IS NOT NULL AND TRIM(p_old_identity_no) <> '' THEN
        -- Numeric format check
        IF p_old_identity_no !~ '^[0-9]+$' THEN
            v_errors := add_error(v_errors, 'old_identity_no', 'Số CMT cũ chỉ được gồm các chữ số 0-9');
        END IF;
        
        -- Length check (9 hoặc 12 chữ số cho CMT cũ)
        IF length(p_old_identity_no) NOT IN (9, 12) THEN
            v_errors := add_error(v_errors, 'old_identity_no', 'Số CMT cũ phải gồm 9 hoặc 12 chữ số');
        END IF;

        -- Uniqueness check
        IF NOT check_unique('employees', 'old_identity_no', p_old_identity_no, p_exclude_id) THEN
            -- Lấy emp_code của nhân viên đã tồn tại
            SELECT emp_code INTO v_existing_emp_code
            FROM employees
            WHERE old_identity_no = p_old_identity_no
            AND (p_exclude_id IS NULL OR id != p_exclude_id)
            LIMIT 1;
            v_errors := add_error(v_errors, 'old_identity_no', format('Số CMT cũ đã tồn tại trong hệ thống với mã nhân viên: %s', v_existing_emp_code));
        END IF;
    END IF;

    -- Old issue date checks
    IF p_old_date_issue IS NOT NULL THEN
        v_error := validate_date(p_old_date_issue, 'old_date_issue', 'Ngày cấp CMT cũ');
        IF v_error IS NOT NULL THEN
            v_errors := add_error(v_errors, 'old_date_issue', v_error->>'message');
        ELSE
            IF p_old_date_issue > CURRENT_DATE THEN
                v_errors := add_error(v_errors, 'old_date_issue', 'Ngày cấp CMT cũ phải là ngày trong quá khứ');
            END IF;
        END IF;
    END IF;

    RETURN v_errors;
END;
$_$;


ALTER FUNCTION public.validate_identity_info(p_identity_no text, p_date_issue date, p_date_identity_expiry date, p_place_issue_id integer, p_old_identity_no text, p_exclude_id integer, p_old_date_issue date, p_old_place_issue_id text) OWNER TO postgres;

--
-- Name: validate_job_position(integer, integer, integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_job_position(p_job_title_id integer, p_organization_id integer, p_work_location_id integer, p_date_join date) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_error JSONB;
BEGIN
    IF p_job_title_id IS NULL THEN
        v_errors := add_error(v_errors, 'job_title_id', 'Chức danh không được để trống');
    ELSIF NOT check_exists('job_titles', 'id', p_job_title_id) THEN
        v_errors := add_error(v_errors, 'job_title_id', 'Chức danh không tồn tại');
    END IF;

    IF p_organization_id IS NULL THEN
        v_errors := add_error(v_errors, 'organization_id', 'Đơn vị công tác không được để trống');
    ELSIF NOT check_exists('organizations', 'id', p_organization_id) THEN
        v_errors := add_error(v_errors, 'organization_id', 'Đơn vị công tác không tồn tại');
    END IF;

    IF p_job_title_id IS NOT NULL AND p_organization_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM job_title_organizations WHERE job_title_id = p_job_title_id AND org_id = p_organization_id
    ) THEN
        v_errors := add_error(v_errors, 'job_title_id and organization_id', 'Vị trí công việc không tồn tại trong đơn vị');
    END IF;

    IF p_work_location_id IS NULL THEN
        v_errors := add_error(v_errors, 'work_location_id', 'Địa điểm làm việc không được để trống');
    ELSIF NOT check_exists('locations', 'id', p_work_location_id) THEN
        v_errors := add_error(v_errors, 'work_location_id', 'Địa điểm làm việc không tồn tại');
    END IF;

    v_error := validate_date(p_date_join, 'date_join', 'Ngày vào làm', TRUE);
    IF v_error IS NOT NULL THEN
        v_errors := add_error(v_errors, 'date_join', v_error->>'message');
    END IF;

    RETURN v_errors;
END;
$$;


ALTER FUNCTION public.validate_job_position(p_job_title_id integer, p_organization_id integer, p_work_location_id integer, p_date_join date) OWNER TO postgres;

--
-- Name: validate_organization_data(integer, date, integer, integer, integer, character varying, character varying, integer, boolean, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_organization_data(p_category_id integer, p_effective_date date, p_parent_org_id integer, p_general_manager_id integer, p_direct_manager_id integer, p_name character varying, p_en_name character varying, p_org_id integer DEFAULT NULL::integer, p_is_active boolean DEFAULT NULL::boolean, p_phone character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE
    v_org RECORD;
    v_sub_org_count INT := 0;
    v_emp_count INT := 0;
    v_exists INT;
    v_org_exists BOOLEAN := FALSE;
    tenant_schema TEXT;
BEGIN
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';
    EXECUTE format('SET search_path TO %I', tenant_schema);

    -- Nếu có truyền p_org_id thì kiểm tra và lấy dữ liệu tổ chức
    IF p_org_id IS NOT NULL THEN
        SELECT * INTO v_org FROM organizations WHERE id = p_org_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Không tìm thấy tổ chức với ID: %', p_org_id;
        END IF;
        v_org_exists := TRUE;
    END IF;

    -- Kiểm tra độ dài chuỗi
    IF p_name IS NOT NULL AND length(p_name) > 255 THEN
        RAISE EXCEPTION 'Tên tổ chức không được vượt quá 255 ký tự';
    END IF;

    IF p_en_name IS NOT NULL AND length(p_en_name) > 255 THEN
        RAISE EXCEPTION 'Tên tiếng Anh không được vượt quá 255 ký tự';
    END IF;

    IF p_phone IS NOT NULL AND length(p_phone) > 30 THEN
        RAISE EXCEPTION 'Số điện thoại không được vượt quá 30 ký tự';
    END IF;

    IF p_email IS NOT NULL AND length(p_email) > 100 THEN
        RAISE EXCEPTION 'Địa chỉ email không được vượt quá 100 ký tự';
    END IF;

    -- Kiểm tra tổ chức cha
    IF p_parent_org_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists FROM organizations WHERE id = p_parent_org_id;
        IF v_exists = 0 THEN
            RAISE EXCEPTION 'Không tìm thấy tổ chức cha với ID: %', p_parent_org_id;
        END IF;
    END IF;

    -- Kiểm tra tổng quản lý
    IF p_general_manager_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists FROM employees WHERE id = p_general_manager_id;
        IF v_exists = 0 THEN
            RAISE EXCEPTION 'Không tìm thấy Tổng quản lý với ID: %', p_general_manager_id;
        END IF;
    END IF;

    -- Kiểm tra quản lý trực tiếp
    IF p_direct_manager_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists FROM employees WHERE id = p_direct_manager_id;
        IF v_exists = 0 THEN
            RAISE EXCEPTION 'Không tìm thấy Quản lý trực tiếp với ID: %', p_direct_manager_id;
        END IF;
    END IF;

    -- Nếu có v_org thì kiểm tra thêm logic thay đổi
    IF v_org_exists THEN
        -- Đếm tổ chức con
        SELECT COUNT(*) INTO v_sub_org_count
        FROM organizations
        WHERE parent_org_id = p_org_id AND is_active = TRUE;

        -- Đếm nhân viên đang làm
        SELECT COUNT(*) INTO v_emp_count
        FROM employees
        WHERE organization_id = p_org_id AND date_resign IS NULL;

        -- Kiểm tra thay đổi category
        IF p_category_id IS NOT NULL AND p_category_id <> v_org.category_id THEN
            IF v_sub_org_count > 0 THEN
                RAISE EXCEPTION 'Không thể thay đổi loại hình tổ chức vì đang có % tổ chức con hoạt động', v_sub_org_count;
            END IF;
        END IF;

    END IF;
END;$$;


ALTER FUNCTION public.validate_organization_data(p_category_id integer, p_effective_date date, p_parent_org_id integer, p_general_manager_id integer, p_direct_manager_id integer, p_name character varying, p_en_name character varying, p_org_id integer, p_is_active boolean, p_phone character varying, p_email character varying) OWNER TO postgres;

--
-- Name: validate_organization_dissolve(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_organization_dissolve(p_org_id integer) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_employee_count INT;
    v_assignment_count INT;
    v_child_org_count INT;
    v_org RECORD;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);
    
    -- Kiểm tra nếu đơn vị tồn tại
    SELECT * INTO v_org FROM organizations WHERE id = p_org_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Tổ chức không tồn tại';
        RETURN;
    END IF;

    -- Kiểm tra nếu đơn vị đang hoạt động
    IF v_org.is_active = FALSE THEN
        RETURN QUERY SELECT FALSE, 'Không thể giải thể vì đơn vị không còn hoạt động';
        RETURN;
    END IF;

    -- Kiểm tra xem đơn vị có nhân sự chính thức, thử việc, hoặc chờ onboard hay không
    SELECT COUNT(*) INTO v_employee_count
    FROM employee_list_view elv
    WHERE elv.organization_id = p_org_id
      AND elv.status IN ('trial', 'waiting', 'active');

    IF v_employee_count > 0 THEN
        RETURN QUERY SELECT FALSE,'Không thể giải thể vì đơn vị còn nhân viên đang làm việc, thử việc hoặc chờ nhận việc';
        RETURN;
    END IF;


    -- Kiểm tra xem đơn vị có nhân sự đang kiêm nhiệm hay không
    SELECT COUNT(*) INTO v_assignment_count FROM job_assignments WHERE org_id = p_org_id AND is_active = TRUE;
    IF v_assignment_count > 0 THEN
        RETURN QUERY SELECT FALSE, 'Không thể giải thể vì đơn vị còn nhân viên kiêm nhiệm';
        RETURN;
    END IF;

    -- Kiểm tra xem đơn vị có đơn vị con còn hoạt động hay không
    SELECT COUNT(*) INTO v_child_org_count 
    FROM organizations 
    WHERE parent_org_id = p_org_id AND is_active = TRUE;

    IF v_child_org_count > 0 THEN
        RETURN QUERY SELECT FALSE, 'Không thể giải thể vì đơn vị còn đơn vị con đang hoạt động';
        RETURN;
    END IF;

    -- Nếu tất cả điều kiện hợp lệ
    RETURN QUERY SELECT TRUE, 'Tổ chức hợp lệ để giải thể';
END;
$$;


ALTER FUNCTION public.validate_organization_dissolve(p_org_id integer) OWNER TO postgres;

--
-- Name: validate_organizations(integer[], integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_organizations(org_ids integer[], target_org_id integer, action_type text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE 
    org_exists BOOLEAN;
    org_id INT;
    target_exists BOOLEAN;
    tenant_schema TEXT;
BEGIN

    -- Lấy schema từ JWT
    tenant_schema := current_setting('request.jwt.claims', true)::jsonb->>'schema';

    -- Thiết lập search_path theo schema
    PERFORM set_config('search_path', tenant_schema, true);

    -- Kiểm tra tổ chức nhận sáp nhập hoặc tổ chức mới sau chia tách
    SELECT EXISTS (SELECT 1 FROM organizations WHERE id = target_org_id AND is_active = TRUE) 
    INTO target_exists;
    
    IF NOT target_exists THEN
        RETURN FORMAT('%s (ID %s) không tồn tại hoặc đã bị vô hiệu hóa.', 
                      CASE 
                          WHEN action_type = 'merge' THEN 'Tổ chức nhận sáp nhập'
                          WHEN action_type = 'split' THEN 'Tổ chức mới sau chia tách'
                      END, target_org_id);
    END IF;

    -- 🔹 Kiểm tra danh sách tổ chức mới có hợp lệ không
    IF array_length(org_ids, 1) IS NULL OR array_length(org_ids, 1) = 0 THEN
        RETURN 'Không được để rổng tổ chức mới!';
    END IF;

    -- Kiểm tra các tổ chức bị ảnh hưởng
    FOREACH org_id IN ARRAY org_ids LOOP
        -- Không thể gộp hoặc tách chính nó
        IF org_id = target_org_id THEN
            RETURN FORMAT('Không thể %s tổ chức vào chính nó (ID %s).',
                          CASE 
                              WHEN action_type = 'merge' THEN 'sáp nhập'
                              WHEN action_type = 'split' THEN 'chia tách'
                          END, target_org_id);
        END IF;

        -- Kiểm tra tổ chức có tồn tại & đang hoạt động không
        SELECT EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND is_active = TRUE) 
        INTO org_exists;

        IF NOT org_exists THEN
            RETURN FORMAT('%s (ID %s) không tồn tại hoặc đã bị vô hiệu hóa.', 
                          CASE 
                              WHEN action_type = 'merge' THEN 'Tổ chức bị sáp nhập'
                              WHEN action_type = 'split' THEN 'Tổ chức bị chia tách'
                          END, org_id);
        END IF;
    END LOOP;

    RETURN 'VALID';
END;
$$;


ALTER FUNCTION public.validate_organizations(org_ids integer[], target_org_id integer, action_type text) OWNER TO postgres;

--
-- Name: validate_phone(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_phone(p_value text, p_field text, p_field_name text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF p_value IS NULL OR TRIM(p_value) = '' THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không được để trống');
    ELSIF NOT p_value ~ '^[0-9]{10,11}$' THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không hợp lệ');
    END IF;
    RETURN NULL;
END;
$_$;


ALTER FUNCTION public.validate_phone(p_value text, p_field text, p_field_name text) OWNER TO postgres;

--
-- Name: validate_required_text(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_required_text(p_value text, p_field text, p_field_name text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_value IS NULL OR TRIM(p_value) = '' THEN
        RETURN jsonb_build_object('field', p_field, 'message', p_field_name || ' không được để trống');
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.validate_required_text(p_value text, p_field text, p_field_name text) OWNER TO postgres;

--
-- Name: validate_reward_disciplinary_input(character varying, character varying, character varying, date, date, date, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_reward_disciplinary_input(p_decision_no character varying, p_issuer character varying, p_issuer_position character varying, p_decision_date date, p_start_date date, p_end_date date, p_type character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Kiểm tra các trường bắt buộc
  IF p_decision_no IS NULL THEN
    RAISE EXCEPTION 'Trường "Số quyết định" không được để trống';
  END IF;

  IF p_issuer IS NULL THEN
    RAISE EXCEPTION 'Trường "Người ký quyết định" không được để trống';
  END IF;

  IF p_issuer_position IS NULL THEN
    RAISE EXCEPTION 'Trường "Chức vụ của người ký" không được để trống';
  END IF;

  IF p_decision_date IS NULL THEN
    RAISE EXCEPTION 'Trường "Ngày ra quyết định" không được để trống';
  END IF;

  IF p_start_date IS NULL THEN
    RAISE EXCEPTION 'Trường "Ngày bắt đầu hiệu lực" không được để trống';
  END IF;

  IF p_type IS NULL THEN
    RAISE EXCEPTION 'Trường "Loại (khen thưởng/kỷ luật)" không được để trống';
  END IF;

  -- Kiểm tra logic ngày tháng
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_start_date > p_end_date THEN
    RAISE EXCEPTION 'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc';
  END IF;
END;
$$;


ALTER FUNCTION public.validate_reward_disciplinary_input(p_decision_no character varying, p_issuer character varying, p_issuer_position character varying, p_decision_date date, p_start_date date, p_end_date date, p_type character varying) OWNER TO postgres;

--
-- Name: validate_update_job_title(character varying, integer, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_update_job_title(p_code character varying, p_job_title_id integer, p_name character varying, p_group_id integer, p_grade_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN
    -- Kiểm tra ID chức danh có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM job_titles WHERE id = p_job_title_id) THEN
        RAISE EXCEPTION 'ID chức danh % không tồn tại.', p_job_title_id;
    END IF;

    -- Kiểm tra không được bỏ trống mã chức danh
    IF p_code IS NULL OR LENGTH(TRIM(p_code)) = 0 THEN
        RAISE EXCEPTION 'Vui lòng nhập mã chức danh.';
    END IF;

    -- Kiểm tra độ dài mã chức danh
    IF LENGTH(TRIM(p_code)) > 50 THEN
        RAISE EXCEPTION 'Mã chức danh không được vượt quá 50 ký tự.';
    END IF;

    -- Kiểm tra định dạng mã chức danh (chỉ cho phép chữ cái, số, dấu gạch dưới, dấu gạch ngang)
    IF TRIM(p_code) !~ '^[a-zA-Z0-9_-]+$' THEN
        RAISE EXCEPTION 'Mã chức danh có định dạng không hợp lệ.';
    END IF;

    -- Kiểm tra mã chức danh có chứa khoảng trắng không
    IF p_code ~ '\s' THEN
        RAISE EXCEPTION 'Mã chức danh không được chứa khoảng trắng.';
    END IF;

    -- Kiểm tra trùng mã chức danh (loại trừ chính bản ghi đang cập nhật)
    IF EXISTS (
        SELECT 1 FROM job_titles 
        WHERE code = TRIM(p_code) 
        AND id != p_job_title_id
    ) THEN
        RAISE EXCEPTION 'Mã chức danh "%" đã tồn tại.', p_code;
    END IF;

    -- Kiểm tra tên chức danh không được để trống
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RAISE EXCEPTION 'Tên chức danh không được để trống.';
    END IF;

    -- Kiểm tra group_id không được để null
    IF p_group_id IS NULL THEN
        RAISE EXCEPTION 'Nhóm chức danh (group_id) không được để trống.';
    END IF;

    -- Kiểm tra group_id có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM job_groups WHERE id = p_group_id) THEN
        RAISE EXCEPTION 'Nhóm chức danh với ID % không tồn tại.', p_group_id;
    END IF;

    -- Kiểm tra grade_id có tồn tại nếu được truyền vào
    IF p_grade_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM job_grades WHERE id = p_grade_id) THEN
        RAISE EXCEPTION 'Ngạch chức danh với ID % không tồn tại.', p_grade_id;
    END IF;

    -- Ghi log kiểm tra thành công
    RAISE LOG 'Kiểm tra hợp lệ thành công cho cập nhật chức danh: id=%s, tên=%s', p_job_title_id, p_name;
END;
$_$;


ALTER FUNCTION public.validate_update_job_title(p_code character varying, p_job_title_id integer, p_name character varying, p_group_id integer, p_grade_id integer) OWNER TO postgres;

--
-- Name: work_histories_insert(integer, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.work_histories_insert(p_emp_id integer, p_end_date date, p_reason text) RETURNS TABLE(status boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_exists_emp INT;
    v_exists_change_type INT;
BEGIN

    IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_emp_id) THEN
        RETURN QUERY
        SELECT FALSE, format('Không tìm thấy nhân viên với ID = %s', p_emp_id);
        RETURN;
    END IF;


    -- Kiểm tra tồn tại change_type
    SELECT el.id INTO v_exists_change_type
    FROM enum_lookup el
    WHERE el.value = (
        SELECT e.job_change_type
        FROM employees e
        WHERE e.id = p_emp_id);

    -- Insert dữ liệu
    INSERT INTO work_histories (
        emp_id, job_title_id, job_title_name, organization_id, organization_name, 
        work_place, change_type_id, decision_no, decision_signer, decision_sign_date, 
        start_date, end_date, reason, note
    )
    SELECT
        e.id, e.job_title_id, jt.name AS job_title_name, 
        e.organization_id, og.name AS organization_name,
        pr.name AS work_place, v_exists_change_type, e.decision_no, 
        e.decision_signer, e.decision_sign_date, COALESCE(e.start_date_change, e.date_join),
        p_end_date, p_reason, e.work_note
    FROM employees e
    JOIN job_titles jt ON jt.id = e.job_title_id
    JOIN organizations og ON og.id = e.organization_id
    JOIN locations lc ON lc.id = e.work_location_id
    JOIN districts dt ON dt.id = lc.districts_id
    JOIN provinces pr ON pr.id = dt.province_id
    WHERE e.id = p_emp_id;

    -- Trả kết quả thành công
    RETURN QUERY
    SELECT TRUE, 'Insert work history thành công';
END;
$$;


ALTER FUNCTION public.work_histories_insert(p_emp_id integer, p_end_date date, p_reason text) OWNER TO postgres;

--
-- Name: abroad_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.abroad_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.abroad_records_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: abroad_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.abroad_records (
    id integer DEFAULT nextval('public.abroad_records_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date,
    national_id integer NOT NULL,
    visas_no character varying(30) NOT NULL,
    type character varying(50) NOT NULL,
    place_issue character varying(100),
    reason text,
    note text
);


ALTER TABLE public.abroad_records OWNER TO postgres;

--
-- Name: actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actions_id_seq
    START WITH 20
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.actions_id_seq OWNER TO postgres;

--
-- Name: actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actions (
    id integer DEFAULT nextval('public.actions_id_seq'::regclass) NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true
);


ALTER TABLE public.actions OWNER TO postgres;

--
-- Name: attachment_link_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attachment_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attachment_link_id_seq OWNER TO postgres;

--
-- Name: attachment_link; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attachment_link (
    id integer DEFAULT nextval('public.attachment_link_id_seq'::regclass) NOT NULL,
    attachment_id integer NOT NULL,
    target_table character varying(100) NOT NULL,
    target_id integer NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT now(),
    type text,
    modified_at timestamp without time zone
);


ALTER TABLE public.attachment_link OWNER TO postgres;

--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attachments_id_seq OWNER TO postgres;

--
-- Name: attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attachments (
    id integer DEFAULT nextval('public.attachments_id_seq'::regclass) NOT NULL,
    file_url character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(50),
    file_size bigint DEFAULT 0,
    created_at timestamp with time zone,
    modified_at timestamp with time zone,
    created_by text,
    modified_by text,
    CONSTRAINT chk_file_size CHECK ((file_size >= 0))
);


ALTER TABLE public.attachments OWNER TO postgres;

--
-- Name: attachment_files_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.attachment_files_view AS
 SELECT a.id,
    al.target_id,
    al.target_table,
    a.id AS attachment_id,
    a.file_url,
    a.created_at,
    a.file_name,
    a.file_type,
    a.file_size
   FROM (public.attachments a
     JOIN public.attachment_link al ON ((a.id = al.attachment_id)));


ALTER VIEW public.attachment_files_view OWNER TO postgres;

--
-- Name: attachment_files_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attachment_files_view_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attachment_files_view_id_seq OWNER TO postgres;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    table_name text NOT NULL,
    operation text NOT NULL,
    record_id integer,
    old_data jsonb,
    new_data jsonb,
    reason text,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by uuid,
    actor_name text,
    actor_role text[],
    realm_roles text[],
    session_id text,
    request_id text,
    tenant_schema text,
    client_ip text
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_seq OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    id integer NOT NULL,
    emp_code character varying NOT NULL,
    emp_code_old text,
    nationality_id integer,
    occupation_id integer,
    last_name character varying(30) NOT NULL,
    middle_name character varying(50),
    first_name character varying(30) NOT NULL,
    full_name character varying(100) NOT NULL,
    gender public.gender NOT NULL,
    religion_id integer,
    ethnicity_id integer,
    temporary_address character varying(100),
    temporary_district_id integer,
    permanent_address character varying(250) NOT NULL,
    permanent_district_id integer,
    email_internal character varying(100) NOT NULL,
    email_external character varying(100),
    phone character varying(30) NOT NULL,
    secondary_phone character varying(30),
    home_phone character varying(30),
    company_phone character varying(30),
    profile_introduced character varying(255),
    job_title_id integer NOT NULL,
    organization_id integer,
    work_location_id integer,
    note text,
    old_identity_no character varying(30),
    old_date_issue date,
    old_place_issue_id text,
    identity_type character varying(50),
    identity_no character varying(30) NOT NULL,
    date_issue date NOT NULL,
    date_identity_expiry date,
    place_issue_id integer NOT NULL,
    date_join date NOT NULL,
    date_probation_start date,
    date_official_start date,
    date_resign date,
    last_work_date date,
    blood_group public.bloodgroup,
    blood_pressure character varying(30),
    height_cm numeric(5,2),
    weight_kg numeric(5,2),
    job_change_type character varying(50),
    manager_id integer,
    decision_no character varying(50),
    decision_signer character varying(255),
    decision_sign_date date,
    start_date_change date,
    end_date_change date,
    work_note character varying(255),
    tax_no character varying(30),
    cif_code text,
    bank_account_no character varying(30),
    bank_name character varying(50),
    is_social_insurance boolean,
    is_unemployment_insurance boolean,
    is_life_insurance boolean,
    party_start_date date,
    union_youth_start_date date,
    party_official_date date,
    military_start_date date,
    military_end_date date,
    military_highest_rank character varying(255),
    is_old_regime boolean,
    is_wounded_soldier boolean,
    en_cert_id integer,
    it_cert_id integer,
    degree_type character varying(50),
    academic text,
    institution character varying(255),
    faculty character varying(50),
    major character varying(255),
    graduation_year date,
    employee_type public.employee_types NOT NULL,
    hometown_provinces_id integer,
    marital_status public.marital_statuses NOT NULL,
    education_level public.education_level NOT NULL,
    dob date,
    avatar text,
    recruitment text,
    union_start_date date,
    union_fee_date date,
    union_decision_no text,
    union_decision_date date,
    union_appointment_no text,
    union_position text,
    union_organization_name character varying(100),
    union_status public.statusunion,
    union_activity text,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_at timestamp with time zone DEFAULT now(),
    modified_by text
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: COLUMN employees.union_youth_start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_youth_start_date IS 'Ngày tham gia đoàn thanh niên';


--
-- Name: COLUMN employees.union_start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_start_date IS 'Ngày tham gia công đoàn';


--
-- Name: COLUMN employees.union_fee_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_fee_date IS 'Ngày đống phí công đoàn';


--
-- Name: COLUMN employees.union_decision_no; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_decision_no IS 'Số quyết định đoàn viên công đoàn';


--
-- Name: COLUMN employees.union_decision_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_decision_date IS 'Ngày ban hành kết nạp công đoàn';


--
-- Name: COLUMN employees.union_appointment_no; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_appointment_no IS 'Số quyết định bổ nhiệm chức vị trong công đoàn';


--
-- Name: COLUMN employees.union_position; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_position IS 'chức danh trong công đoàn';


--
-- Name: COLUMN employees.union_organization_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_organization_name IS 'Tên cơ quan công đoàn';


--
-- Name: COLUMN employees.union_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_status IS 'trạng thái hoạt động công đoàn. VD: ''Đang hoạt động'',''Đã rời đoàn'', ''Tạm dừng''';


--
-- Name: COLUMN employees.union_activity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employees.union_activity IS 'Các hoạt đọng tham gia của công đoàn';


--
-- Name: job_titles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_titles_id_seq
    START WITH 1564
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_titles_id_seq OWNER TO postgres;

--
-- Name: job_titles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_titles (
    id integer DEFAULT nextval('public.job_titles_id_seq'::regclass) NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    en_name character varying(100),
    foreign_name character varying(100),
    group_id integer NOT NULL,
    is_management boolean DEFAULT false NOT NULL,
    grade_id integer,
    parent_id integer,
    cost_center_id integer,
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_at timestamp with time zone DEFAULT now(),
    modified_by text,
    CONSTRAINT chk_job_title_code_not_empty CHECK ((TRIM(BOTH FROM code) <> ''::text)),
    CONSTRAINT chk_job_title_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);


ALTER TABLE public.job_titles OWNER TO postgres;

--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 2110
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organizations_id_seq OWNER TO postgres;

--
-- Name: organizations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.organizations (
    id integer DEFAULT nextval('public.organizations_id_seq'::regclass) NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(255) NOT NULL,
    en_name character varying(255),
    category_id integer NOT NULL,
    parent_org_id integer,
    location_id integer,
    phone character varying(30),
    email character varying(100),
    effective_date date,
    expired_date date,
    cost_centers_id integer,
    is_active boolean DEFAULT true,
    decision_no character varying(30),
    decision_date date,
    version integer DEFAULT 1,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    modified_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_by text,
    general_manager_id integer,
    direct_manager_id integer,
    approve_struct public.approve_struct_enum,
    CONSTRAINT chk_code_not_empty CHECK ((TRIM(BOTH FROM code) <> ''::text)),
    CONSTRAINT chk_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text)),
    CONSTRAINT chk_version_positive CHECK ((version > 0))
);


ALTER TABLE public.organizations OWNER TO postgres;

--
-- Name: COLUMN organizations.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.id IS 'Mã định danh duy nhất của tổ chức (tự động tăng), Ví dụ: 1001';


--
-- Name: COLUMN organizations.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.code IS 'Mã code của tổ chức, Ví dụ: ''KLB'', ''HĐQ'', ''PGD''';


--
-- Name: COLUMN organizations.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.name IS 'Tên của tổ chức hoặc đơn vị trực thuộc, Ví dụ: Ngân hàng Kiên Long, Hội đồng quản trị, Trung tâm Vận hành, Chi nhánh Hà Nội';


--
-- Name: COLUMN organizations.en_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.en_name IS 'Tên tiếng Anh của tổ chức hoặc đơn vị trực thuộc, Ví dụ: Kien Long Bank, Board of Directors, Operation Center, Hanoi Branch';


--
-- Name: COLUMN organizations.category_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.category_id IS 'Loại tổ chức, Ví dụ: Organization (Tổ chức tổng), Unit (Đơn vị), Division (Khối), Department (Phòng ban), Center (Trung tâm), Team (Tổ nhóm), Branch (Chi nhánh), PGD (Phòng giao dịch)';


--
-- Name: COLUMN organizations.parent_org_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.parent_org_id IS 'Mã tổ chức cha (tự liên kết với bảng `public.organizations`), giúp xác định quan hệ cha - con giữa các đơn vị, Ví dụ: Hội sở chính có `parent_org_id = 1001` thuộc Ngân hàng Kiên Long';


--
-- Name: COLUMN organizations.location_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.location_id IS 'Địa chỉ cụ thể của tổ chức, Ví dụ: 117 Nguyễn Văn Trỗi';


--
-- Name: COLUMN organizations.phone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.phone IS 'Số điện thoại liên hệ của tổ chức, Ví dụ: 02839999999';


--
-- Name: COLUMN organizations.effective_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.effective_date IS 'Ngày tổ chức hoặc đơn vị bắt đầu có hiệu lực, Ví dụ: 2000-01-01';


--
-- Name: COLUMN organizations.expired_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.expired_date IS 'Ngày tổ chức hoặc đơn vị hết hiệu lực (nếu có), Ví dụ: 2050-12-31 hoặc NULL nếu vẫn còn hoạt động';


--
-- Name: COLUMN organizations.cost_centers_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.cost_centers_id IS 'Mã trung tâm chi phí (liên kết với bảng `cost_centers`), giúp quản lý ngân sách và chi phí của tổ chức';


--
-- Name: COLUMN organizations.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.is_active IS 'Trạng thái hoạt động của tổ chức (true = Đang hoạt động, false = Ngừng hoạt động)';


--
-- Name: COLUMN organizations.version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.version IS 'Số phiên bản của tổ chức, giúp theo dõi sự thay đổi theo thời gian, Ví dụ: 1, 2, 3';


--
-- Name: COLUMN organizations.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.description IS 'Mô tả chi tiết về tổ chức hoặc đơn vị, phạm vi hoạt động, lĩnh vực kinh doanh hoặc chức năng, Ví dụ: Quản lý và điều hành toàn bộ ngân hàng';


--
-- Name: COLUMN organizations.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.created_at IS 'Ngày tạo đơn vị';


--
-- Name: COLUMN organizations.created_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.created_by IS 'Người tạo đơn vị';


--
-- Name: COLUMN organizations.modified_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.modified_by IS 'Người chỉnh sửa';


--
-- Name: COLUMN organizations.general_manager_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.general_manager_id IS 'Khóa ngoại liên kết đến nhân viên xem ai là người phụ trách chung';


--
-- Name: COLUMN organizations.direct_manager_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.direct_manager_id IS 'Khóa ngoại liên kết đến nhân viên xem ai là người phụ trách trực tiếp';


--
-- Name: employee_list_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_list_view AS
 SELECT e.id,
    e.emp_code AS code,
    e.emp_code_old,
    e.full_name,
    e.gender,
    e.email_internal,
    e.phone,
    e.dob,
    o.id AS organization_id,
    o.name AS organization_name,
    jt.id AS job_title_id,
    jt.name AS job_title_name,
    jt.sort_order,
    e.date_join,
    e.date_resign,
    e.date_probation_start,
    e.date_official_start,
    e.avatar,
        CASE
            WHEN ((e.date_resign IS NOT NULL) AND (e.date_resign <= CURRENT_DATE)) THEN 'terminated'::text
            WHEN ((e.date_resign IS NOT NULL) AND (e.date_join IS NOT NULL) AND (e.date_probation_start IS NULL) AND (e.date_official_start IS NULL)) THEN 'declined'::text
            WHEN ((e.date_probation_start IS NOT NULL) AND (e.date_official_start IS NULL)) THEN 'trial'::text
            WHEN ((e.date_join IS NOT NULL) AND (e.date_join >= CURRENT_DATE) AND ((e.date_probation_start IS NULL) OR (e.date_official_start IS NULL)) AND (e.date_resign IS NULL)) THEN 'waiting'::text
            WHEN ((e.date_join IS NOT NULL) AND (e.date_join <= CURRENT_DATE) AND ((e.date_resign IS NULL) OR (e.date_resign > CURRENT_DATE))) THEN 'active'::text
            ELSE 'unknown'::text
        END AS status
   FROM ((public.employees e
     LEFT JOIN public.job_titles jt ON ((e.job_title_id = jt.id)))
     LEFT JOIN public.organizations o ON ((e.organization_id = o.id)))
  ORDER BY jt.sort_order;


ALTER VIEW public.employee_list_view OWNER TO postgres;

--
-- Name: birthdays_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.birthdays_view AS
 SELECT id,
    full_name,
    dob,
    organization_id,
    organization_name,
    job_title_id,
    job_title_name,
    avatar,
    date_join
   FROM public.employee_list_view e
  WHERE ((to_char((dob)::timestamp with time zone, 'MM-DD'::text) = to_char((CURRENT_DATE)::timestamp with time zone, 'MM-DD'::text)) AND (status = ANY (ARRAY['active'::text, 'trial'::text])))
  ORDER BY date_join DESC;


ALTER VIEW public.birthdays_view OWNER TO postgres;

--
-- Name: certificates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.certificates_id_seq
    START WITH 4102
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.certificates_id_seq OWNER TO postgres;

--
-- Name: certificates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.certificates (
    id integer DEFAULT nextval('public.certificates_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    type_id integer,
    cert_no character varying(30),
    name character varying(100) NOT NULL,
    issued_by character varying(100),
    date_issue date,
    expired_date date,
    note character varying(255)
);


ALTER TABLE public.certificates OWNER TO postgres;

--
-- Name: cost_centers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cost_centers_id_seq
    START WITH 1306
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cost_centers_id_seq OWNER TO postgres;

--
-- Name: cost_centers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cost_centers (
    id integer DEFAULT nextval('public.cost_centers_id_seq'::regclass) NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(255) NOT NULL,
    en_name character varying(255),
    budget_allocated numeric(18,2) DEFAULT 0,
    budget_used numeric(18,2) DEFAULT 0,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_budget_allocated_non_negative CHECK (((budget_allocated IS NULL) OR (budget_allocated >= (0)::numeric))),
    CONSTRAINT chk_budget_used_lte_allocated CHECK (((budget_used IS NULL) OR (budget_allocated IS NULL) OR (budget_used <= budget_allocated))),
    CONSTRAINT chk_budget_used_non_negative CHECK (((budget_used IS NULL) OR (budget_used >= (0)::numeric))),
    CONSTRAINT chk_code_not_empty CHECK ((TRIM(BOTH FROM code) <> ''::text)),
    CONSTRAINT chk_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);


ALTER TABLE public.cost_centers OWNER TO postgres;

--
-- Name: COLUMN cost_centers.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.id IS 'Mã trung tâm chi phí, duy nhất';


--
-- Name: COLUMN cost_centers.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.code IS 'Mã định danh của Cost Center, ví dụ: IT, HR, Training';


--
-- Name: COLUMN cost_centers.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.name IS 'Tên tiếng Việt của Cost Center, ví dụ: Phòng CNTT, Phòng Nhân sự, Trung tâm Đào tạo';


--
-- Name: COLUMN cost_centers.en_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.en_name IS 'Tên tiếng Anh của Cost Center, ví dụ: IT Department, HR Division, Training Cost';


--
-- Name: COLUMN cost_centers.budget_allocated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.budget_allocated IS 'Ngân sách phân bổ ban đầu';


--
-- Name: COLUMN cost_centers.budget_used; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.budget_used IS 'Ngân sách đã sử dụng thực tế';


--
-- Name: COLUMN cost_centers.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cost_centers.is_active IS 'Trạng thái của Cost Center: true - Active, false - Inactive';


--
-- Name: degrees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.degrees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.degrees_id_seq OWNER TO postgres;

--
-- Name: degrees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.degrees (
    id integer DEFAULT nextval('public.degrees_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    is_main boolean DEFAULT false,
    type character varying(50),
    degree_no character varying(30) NOT NULL,
    academic text NOT NULL,
    institution text,
    classification character varying(30),
    faculty character varying(50),
    major character varying(255),
    education_mode character varying(50),
    start_date date,
    end_date date,
    graduation_year date,
    training_location character varying(30),
    note character varying(255)
);


ALTER TABLE public.degrees OWNER TO postgres;

--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.districts_id_seq
    START WITH 2494
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.districts_id_seq OWNER TO postgres;

--
-- Name: districts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.districts (
    id integer DEFAULT nextval('public.districts_id_seq'::regclass) NOT NULL,
    province_id integer NOT NULL,
    name character varying(30) NOT NULL,
    en_name character varying(30),
    note character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT chk_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text)),
    CONSTRAINT chk_province_id_positive CHECK ((province_id > 0))
);


ALTER TABLE public.districts OWNER TO postgres;

--
-- Name: COLUMN districts.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.id IS 'Khóa chính, mã định danh duy nhất của quận/huyện, VD: 101';


--
-- Name: COLUMN districts.province_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.province_id IS 'Khóa ngoại tham chiếu đến tỉnh/thành phố, VD: 79 (TP.HCM)';


--
-- Name: COLUMN districts.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.name IS 'Tên quận/huyện có dấu tiếng Việt, VD: ''Quận 1''';


--
-- Name: COLUMN districts.en_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.en_name IS 'Tên quận/huyện không dấu, VD: ''Quan 1''';


--
-- Name: COLUMN districts.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.note IS 'Thông tin ghi chú, VD: ''Khu trung tâm kinh tế''';


--
-- Name: COLUMN districts.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.is_active IS 'Trạng thái sử dụng, ''true'' nếu đang hoạt động, ''false'' nếu ngừng sử dụng';


--
-- Name: COLUMN districts.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.districts.description IS 'Mô tả';


--
-- Name: emp_draft_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.emp_draft_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.emp_draft_id_seq OWNER TO postgres;

--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.locations_id_seq
    START WITH 1122
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.locations_id_seq OWNER TO postgres;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations (
    id integer DEFAULT nextval('public.locations_id_seq'::regclass) NOT NULL,
    name character varying(255),
    districts_id integer NOT NULL,
    address character varying NOT NULL,
    description text,
    CONSTRAINT chk_address_not_empty CHECK ((TRIM(BOTH FROM address) <> ''::text)),
    CONSTRAINT chk_districts_id_positive CHECK ((districts_id > 0)),
    CONSTRAINT chk_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- Name: COLUMN locations.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.locations.id IS 'Khóa chính, mã định danh duy nhất cho địa điểm. Ví dụ: 1, 2, 3';


--
-- Name: COLUMN locations.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.locations.name IS 'Tên địa điểm làm việc và tên của đơn vị, Ví dụ: ''Kiên Long Bank Phú Nhuận'', ''Chi nhánh Hà Nội''';


--
-- Name: COLUMN locations.districts_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.locations.districts_id IS 'khóa ngoại liên kết đến Quận/huyện';


--
-- Name: COLUMN locations.address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.locations.address IS 'Số đường địa chỉ làm việc';


--
-- Name: COLUMN locations.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.locations.description IS 'Mô tả chi tiết về địa điểm, ví dụ: ''Trụ sở chính tại TP. HCM'', ''Chi nhánh tại Hà Nội''';


--
-- Name: employee_contacts_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_contacts_view AS
 SELECT e.phone,
        CASE
            WHEN (e.date_resign IS NOT NULL) THEN 'terminated'::text
            WHEN ((e.date_probation_start IS NOT NULL) AND (e.date_official_start IS NULL)) THEN 'trial'::text
            WHEN ((e.date_join IS NOT NULL) AND (e.date_resign IS NULL)) THEN 'active'::text
            ELSE 'unknown'::text
        END AS status,
    e.emp_code,
    org.id AS organization_id,
    org.name AS organization_name,
    org.direct_manager_id,
    dm.full_name AS direct_manager_name,
    org.general_manager_id,
    gm.full_name AS general_manager_name,
    e.date_join,
    jt.name AS job_title,
    e.avatar AS avatar_url,
    e.id AS employee_id,
    e.emp_code AS employee_code,
    e.full_name AS employee_name,
    e.email_internal,
    jt.code AS job_title_code,
    e.secondary_phone,
    e.work_location_id,
    concat(loc.name, ' - ', loc.address) AS work_location_name
   FROM (((((public.employees e
     JOIN public.job_titles jt ON ((e.job_title_id = jt.id)))
     JOIN public.organizations org ON ((e.organization_id = org.id)))
     LEFT JOIN public.employees dm ON ((org.direct_manager_id = dm.id)))
     LEFT JOIN public.employees gm ON ((org.general_manager_id = gm.id)))
     LEFT JOIN public.locations loc ON ((e.work_location_id = loc.id)));


ALTER VIEW public.employee_contacts_view OWNER TO postgres;

--
-- Name: enum_lookup_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.enum_lookup_id_seq
    START WITH 1759
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enum_lookup_id_seq OWNER TO postgres;

--
-- Name: enum_lookup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enum_lookup (
    id integer DEFAULT nextval('public.enum_lookup_id_seq'::regclass) NOT NULL,
    category_id integer NOT NULL,
    value character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0,
    description text,
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    created_by text,
    modified_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    modified_by text,
    CONSTRAINT enum_lookup_is_active_check CHECK ((is_active = ANY (ARRAY[true, false]))),
    CONSTRAINT enum_lookup_name_check CHECK (((length(TRIM(BOTH FROM name)) >= 1) AND (length(TRIM(BOTH FROM name)) <= 100))),
    CONSTRAINT enum_lookup_sort_order_check CHECK ((sort_order >= 0)),
    CONSTRAINT enum_lookup_value_check CHECK (((length(TRIM(BOTH FROM value)) >= 1) AND (length(TRIM(BOTH FROM value)) <= 100)))
);


ALTER TABLE public.enum_lookup OWNER TO postgres;

--
-- Name: national_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.national_id_seq
    START WITH 107
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.national_id_seq OWNER TO postgres;

--
-- Name: national; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."national" (
    id integer DEFAULT nextval('public.national_id_seq'::regclass) NOT NULL,
    code character(30) NOT NULL,
    name text,
    en_name text,
    is_active boolean NOT NULL
);


ALTER TABLE public."national" OWNER TO postgres;

--
-- Name: provinces_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.provinces_id_seq
    START WITH 378
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.provinces_id_seq OWNER TO postgres;

--
-- Name: provinces; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provinces (
    id integer DEFAULT nextval('public.provinces_id_seq'::regclass) NOT NULL,
    code character(30) NOT NULL,
    name character varying(30) NOT NULL,
    en_name character varying(30),
    rank integer,
    note character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT chk_code_not_empty CHECK ((TRIM(BOTH FROM code) <> ''::text)),
    CONSTRAINT chk_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);


ALTER TABLE public.provinces OWNER TO postgres;

--
-- Name: COLUMN provinces.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.id IS 'Khóa chính, mã định danh duy nhất của tỉnh/thành phố, VD: 79';


--
-- Name: COLUMN provinces.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.code IS 'Mã code của tỉnh/thành phố theo quy chuẩn, VD: ''HCM''';


--
-- Name: COLUMN provinces.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.name IS 'Tên tỉnh/thành phố có dấu tiếng Việt, VD: ''Hồ Chí Minh''';


--
-- Name: COLUMN provinces.en_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.en_name IS 'Tên tỉnh/thành phố không dấu, VD: ''Ho Chi Minh''';


--
-- Name: COLUMN provinces.rank; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.rank IS 'Xếp hạng của tỉnh/thành phố theo tiêu chí nhất định, VD: 1';


--
-- Name: COLUMN provinces.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.note IS 'Thông tin ghi chú, VD: ''Thành phố lớn nhất Việt Nam''';


--
-- Name: COLUMN provinces.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.is_active IS 'Trạng thái sử dụng, ''true'' nếu đang hoạt động, ''false'' nếu ngừng sử dụng';


--
-- Name: COLUMN provinces.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.provinces.description IS 'Mô tả';


--
-- Name: employee_detail_profile_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_detail_profile_view AS
 SELECT e.id,
    e.emp_code,
    e.last_name,
    e.middle_name,
    e.first_name,
    e.full_name,
    e.gender,
    e.avatar,
    e.marital_status,
    e.dob,
    n.name AS nationality_name,
    occ.name AS occupation_name,
    rel.name AS religion_name,
    eth.name AS ethnicity_name,
    hometown.name AS hometown_name,
    e.temporary_address,
    temp_dist.id AS temp_dist_id,
    temp_dist.name AS temporary_district_name,
    temp_prov.id AS temp_prov_id,
    temp_prov.name AS temporary_province_name,
    e.permanent_address,
    perm_dist.id AS perm_dist_id,
    perm_dist.name AS permanent_district_name,
    perm_prov.id AS perm_prov_id,
    perm_prov.name AS permanent_province_name,
    e.email_internal,
    e.email_external,
    e.phone,
    e.secondary_phone,
    e.home_phone,
    e.company_phone,
    e.job_title_id,
    jt.name AS job_title_name,
    e.organization_id AS org_id,
    org.name AS organization_name,
    loc.name AS work_location_name,
    loc.address AS work_location_address,
    e.date_join,
    e.date_probation_start,
    e.date_official_start,
    e.date_resign,
    e.last_work_date,
    e.job_change_type,
    job_change.name AS job_change_type_name,
    e.decision_no,
    e.decision_signer,
    e.decision_sign_date,
    e.start_date_change,
    e.end_date_change,
    e.work_note,
    e.note,
    e.old_identity_no,
    e.old_date_issue,
    e.old_place_issue_id,
    e.identity_type,
    e.identity_no,
    e.date_issue,
    e.date_identity_expiry,
    place.name AS place_issue_name,
    e.blood_group,
    e.blood_pressure,
    e.height_cm,
    e.weight_kg,
    e.education_level,
    e.profile_introduced,
    e.degree_type,
    e.academic,
    e.institution,
    e.faculty,
    e.major,
    e.graduation_year,
    en_cert.name AS en_cert_name,
    it_cert.name AS it_cert_name,
    e.tax_no,
    e.cif_code,
    e.bank_account_no,
    e.bank_name,
    e.is_social_insurance,
    e.is_unemployment_insurance,
    e.is_life_insurance,
    e.party_start_date,
    e.union_youth_start_date,
    e.party_official_date,
    e.military_start_date,
    e.military_end_date,
    e.military_highest_rank,
    e.is_old_regime,
    e.is_wounded_soldier,
    e.employee_type AS type,
    e.union_start_date,
    e.union_fee_date,
    e.union_decision_no,
    e.union_decision_date,
    e.union_appointment_no,
    e.union_position,
    e.union_organization_name,
    e.union_status,
    e.union_activity,
    e.employee_type,
    e.manager_id,
    manager.full_name AS manager_name,
    manager.emp_code AS manager_code,
    elv.status
   FROM ((((((((((((((((((public.employees e
     LEFT JOIN public.enum_lookup occ ON ((e.occupation_id = occ.id)))
     LEFT JOIN public.enum_lookup rel ON ((e.religion_id = rel.id)))
     LEFT JOIN public.enum_lookup eth ON ((e.ethnicity_id = eth.id)))
     LEFT JOIN public.enum_lookup en_cert ON ((e.en_cert_id = en_cert.id)))
     LEFT JOIN public.enum_lookup it_cert ON ((e.it_cert_id = it_cert.id)))
     LEFT JOIN public.enum_lookup job_change ON (((e.job_change_type)::text = (job_change.value)::text)))
     LEFT JOIN public.enum_lookup place ON ((e.place_issue_id = place.id)))
     LEFT JOIN public."national" n ON ((e.nationality_id = n.id)))
     LEFT JOIN public.provinces hometown ON ((e.hometown_provinces_id = hometown.id)))
     LEFT JOIN public.districts temp_dist ON ((e.temporary_district_id = temp_dist.id)))
     LEFT JOIN public.provinces temp_prov ON ((temp_dist.province_id = temp_prov.id)))
     LEFT JOIN public.districts perm_dist ON ((e.permanent_district_id = perm_dist.id)))
     LEFT JOIN public.provinces perm_prov ON ((perm_dist.province_id = perm_prov.id)))
     LEFT JOIN public.job_titles jt ON ((e.job_title_id = jt.id)))
     LEFT JOIN public.organizations org ON ((e.organization_id = org.id)))
     LEFT JOIN public.locations loc ON ((e.work_location_id = loc.id)))
     LEFT JOIN public.employees manager ON ((e.manager_id = manager.id)))
     JOIN public.employee_list_view elv ON ((e.id = elv.id)));


ALTER VIEW public.employee_detail_profile_view OWNER TO postgres;

--
-- Name: employee_detail_profile_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_detail_profile_view_id_seq
    START WITH 9222
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_detail_profile_view_id_seq OWNER TO postgres;

--
-- Name: employee_health_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_health_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_health_id_seq OWNER TO postgres;

--
-- Name: employee_health; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee_health (
    id integer DEFAULT nextval('public.employee_health_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    examination_date date NOT NULL,
    hospital character varying(150) NOT NULL,
    examiner character varying(255),
    health_evaluate public.healthevaluate NOT NULL,
    health_status text,
    doctor_recommend text,
    note text
);


ALTER TABLE public.employee_health OWNER TO postgres;

--
-- Name: employee_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_histories_id_seq
    START WITH 178089
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_histories_id_seq OWNER TO postgres;

--
-- Name: employee_histories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee_histories (
    id integer DEFAULT nextval('public.employee_histories_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    action character varying(50) NOT NULL,
    log_date timestamp without time zone DEFAULT now(),
    emp_code character varying(20) NOT NULL,
    emp_code_old character varying(20),
    nationality_id integer,
    enum_info jsonb,
    last_name character varying(30),
    middle_name character varying(50),
    first_name character varying(30),
    full_name character varying(100),
    gender character varying(10),
    temporary_address character varying(100),
    temporary_district_id integer,
    hometown_provinces_id integer,
    permanent_address character varying(250),
    permanent_district_id integer,
    email_internal character varying(100),
    email_external character varying(100),
    phone character varying(30),
    secondary_phone character varying(30),
    home_phone character varying(30),
    company_phone character varying(30),
    marital_status character varying(50),
    education_level character varying(50),
    profile_introduced character varying(255),
    job_title_id integer,
    organization_id integer,
    work_location_id integer,
    avatar character varying(255),
    note text,
    old_identity_no character varying(30),
    old_date_issue date,
    old_place_issue_id text,
    identity_type character varying(50),
    identity_no character varying(30),
    date_issue date,
    date_identity_expiry date,
    place_issue_id integer,
    date_join date,
    date_probation_start date,
    date_official_start date,
    date_resign date,
    last_work_date date,
    blood_group character varying(5),
    blood_pressure character varying(30),
    height_cm numeric(5,2),
    weight_kg numeric(5,2),
    job_change_type character varying(50),
    manager_id integer,
    decision_no character varying(50),
    decision_signer character varying(255),
    decision_sign_date date,
    start_date_change date,
    end_date_change date,
    work_note character varying(255),
    tax_no character varying(30),
    cif_code text,
    bank_account_no character varying(30),
    bank_name character varying(50),
    is_social_insurance boolean,
    is_unemployment_insurance boolean,
    is_life_insurance boolean,
    party_start_date date,
    party_official_date date,
    military_start_date date,
    military_end_date date,
    military_highest_rank character varying(255),
    is_old_regime boolean,
    is_wounded_soldier boolean,
    en_cert_id integer,
    it_cert_id integer,
    degree_type character varying(50),
    academic text,
    institution character varying(255),
    faculty character varying(50),
    major character varying(255),
    graduation_year date,
    degree_info jsonb,
    certif_info jsonb,
    rewards_discipline jsonb,
    external_work jsonb,
    family_relationships jsonb,
    employee_type character varying(50),
    log_type character varying(20) DEFAULT 'MANUAL'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    created_by text,
    modified_at timestamp with time zone DEFAULT now(),
    modified_by text,
    internal_working jsonb,
    dob date NOT NULL,
    recruitment text,
    certificate_name text,
    union_youth_start_date date,
    union_start_date date,
    union_fee_date date,
    union_decision_no text,
    union_decision_date date,
    union_appointment_no text,
    union_position text,
    union_organization_name character varying(100),
    union_status public.statusunion,
    union_activity text,
    hometown_provinces_name text,
    temporary_district_name text,
    permanent_district_name text,
    manager_name text,
    work_location_address text,
    organization_name text,
    job_title_name text,
    nationality_name text
);


ALTER TABLE public.employee_histories OWNER TO postgres;

--
-- Name: COLUMN employee_histories.internal_working; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employee_histories.internal_working IS 'Quá trình làm việc nôi bộ';


--
-- Name: COLUMN employee_histories.dob; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.employee_histories.dob IS 'Ngày sinh';


--
-- Name: employee_list_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_list_view_id_seq
    START WITH 9222
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_list_view_id_seq OWNER TO postgres;

--
-- Name: employee_statistics_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_statistics_view AS
 WITH current_metrics AS (
         SELECT count(*) FILTER (WHERE (employee_list_view.status <> 'terminated'::text)) AS total_employees,
            count(*) FILTER (WHERE (employee_list_view.status = ANY (ARRAY['active'::text, 'trial'::text]))) AS active_employees,
            count(*) FILTER (WHERE ((employee_list_view.date_join >= (CURRENT_DATE - '30 days'::interval)) AND (employee_list_view.date_join <= CURRENT_DATE))) AS new_employees_30_days,
            count(*) FILTER (WHERE ((employee_list_view.date_resign >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (employee_list_view.date_resign < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)))) AS resign_current_month,
            round((((count(*) FILTER (WHERE ((employee_list_view.date_resign >= date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)) AND (employee_list_view.date_resign < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) + '1 mon'::interval)))))::numeric / (NULLIF(count(*) FILTER (WHERE ((employee_list_view.status <> 'terminated'::text) AND (employee_list_view.date_join < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))), 0))::numeric) * (100)::numeric), 1) AS turnover_rate
           FROM public.employee_list_view
        ), previous_metrics AS (
         SELECT count(*) FILTER (WHERE ((employee_list_view.status <> 'terminated'::text) AND (employee_list_view.date_join < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))) AS total_employees_prev,
            count(*) FILTER (WHERE ((employee_list_view.status = ANY (ARRAY['active'::text, 'trial'::text])) AND (employee_list_view.date_join < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))) AS active_employees_prev,
            count(*) FILTER (WHERE ((employee_list_view.date_join >= ((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval) - '30 days'::interval)) AND (employee_list_view.date_join < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '30 days'::interval)))) AS new_employees_30_days_prev,
            count(*) FILTER (WHERE ((employee_list_view.date_resign >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval)) AND (employee_list_view.date_resign < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))) AS resign_prev_month,
            round((((count(*) FILTER (WHERE ((employee_list_view.date_resign >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval)) AND (employee_list_view.date_resign < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))))::numeric / (NULLIF(count(*) FILTER (WHERE ((employee_list_view.status <> 'terminated'::text) AND (employee_list_view.date_join < (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone) - '1 mon'::interval)))), 0))::numeric) * (100)::numeric), 1) AS turnover_rate_prev
           FROM public.employee_list_view
        )
 SELECT c.total_employees,
    round(
        CASE
            WHEN (c.total_employees > 0) THEN ((((c.total_employees - COALESCE(p.total_employees_prev, (0)::bigint)))::numeric / (c.total_employees)::numeric) * (100)::numeric)
            ELSE (0)::numeric
        END, 1) AS total_employees_change_pct,
    c.active_employees,
    round(
        CASE
            WHEN (c.active_employees > 0) THEN ((((c.active_employees - COALESCE(p.active_employees_prev, (0)::bigint)))::numeric / (c.active_employees)::numeric) * (100)::numeric)
            ELSE (0)::numeric
        END, 1) AS active_employees_change_pct,
    c.new_employees_30_days,
    round(
        CASE
            WHEN (c.new_employees_30_days > 0) THEN ((((c.new_employees_30_days - COALESCE(p.new_employees_30_days_prev, (0)::bigint)))::numeric / (c.new_employees_30_days)::numeric) * (100)::numeric)
            ELSE (0)::numeric
        END, 1) AS new_employees_30_days_change_pct,
    COALESCE(c.turnover_rate, (0)::numeric) AS turnover_rate,
    round(
        CASE
            WHEN (p.resign_prev_month > 0) THEN ((((c.resign_current_month - p.resign_prev_month))::numeric / (p.resign_prev_month)::numeric) * (100)::numeric)
            ELSE (0)::numeric
        END, 1) AS turnover_rate_change_pct
   FROM (current_metrics c
     CROSS JOIN previous_metrics p);


ALTER VIEW public.employee_statistics_view OWNER TO postgres;

--
-- Name: employees_export_full_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employees_export_full_view AS
 SELECT e.id,
    e.emp_code,
    e.emp_code_old,
    nat.name AS nationality,
    occ.name AS occupation,
    e.last_name,
    e.middle_name,
    e.first_name,
    e.full_name,
    e.gender,
    rel.name AS religion,
    eth.name AS ethnicity,
    e.temporary_address,
    td.name AS temporary_district,
    tp.name AS temporary_province,
    e.permanent_address,
    pd.name AS permanent_district,
    pp.name AS permanent_province,
    e.email_internal,
    e.email_external,
    e.phone,
    e.secondary_phone,
    e.home_phone,
    e.company_phone,
    e.profile_introduced,
    e.job_title_id,
    jt.name AS job_title,
    e.organization_id,
    org.name AS organization,
    wl.address AS work_location,
    e.note,
    e.old_identity_no,
    e.old_date_issue,
    e.old_place_issue_id,
    e.identity_type,
    e.identity_no,
    e.date_issue,
    e.date_identity_expiry,
    pi.name AS place_issue,
    e.date_join,
    e.date_probation_start,
    e.date_official_start,
    e.date_resign,
    e.last_work_date,
    e.blood_group,
    e.blood_pressure,
    e.height_cm,
    e.weight_kg,
    job_change_lookup.name AS job_change,
    mng.full_name AS manager_name,
    e.decision_no,
    e.decision_signer,
    e.decision_sign_date,
    e.start_date_change,
    e.end_date_change,
    e.work_note,
    e.tax_no,
    e.cif_code,
    e.bank_account_no,
    e.bank_name,
    e.is_social_insurance,
    e.is_unemployment_insurance,
    e.is_life_insurance,
    e.party_start_date,
    e.union_youth_start_date,
    e.party_official_date,
    e.military_start_date,
    e.military_end_date,
    e.military_highest_rank,
    e.is_old_regime,
    e.is_wounded_soldier,
    en.name AS en_cert,
    it.name AS it_cert,
    e.degree_type,
    e.academic,
    e.institution,
    e.faculty,
    e.major,
    e.graduation_year,
    e.employee_type,
    hp.name AS hometown_province,
    e.marital_status,
    e.education_level,
    e.dob,
    e.avatar,
    e.recruitment,
    e.union_start_date,
    e.union_fee_date,
    e.union_decision_no,
    e.union_decision_date,
    e.union_appointment_no,
    e.union_position,
    e.union_organization_name,
    e.union_status,
    e.union_activity,
    e.created_at,
    e.created_by,
    e.modified_at,
    e.modified_by,
        CASE
            WHEN ((e.date_resign IS NOT NULL) AND (e.date_join IS NOT NULL) AND ((e.date_probation_start IS NULL) OR (e.date_official_start IS NULL))) THEN 'declined'::text
            WHEN ((e.date_resign IS NOT NULL) AND (e.date_resign <= CURRENT_DATE)) THEN 'terminated'::text
            WHEN ((e.date_probation_start IS NOT NULL) AND (e.date_official_start IS NULL)) THEN 'trial'::text
            WHEN ((e.date_join IS NOT NULL) AND (e.date_join < CURRENT_DATE) AND (e.date_probation_start IS NULL) AND (e.date_official_start IS NULL) AND (e.date_resign IS NULL)) THEN 'missed_start'::text
            WHEN ((e.date_join IS NOT NULL) AND (e.date_join >= CURRENT_DATE) AND ((e.date_probation_start IS NULL) OR (e.date_official_start IS NULL)) AND (e.date_resign IS NULL)) THEN 'waiting'::text
            WHEN ((e.date_join IS NOT NULL) AND (e.date_join <= CURRENT_DATE) AND ((e.date_resign IS NULL) OR (e.date_resign > CURRENT_DATE)) AND ((e.date_probation_start IS NOT NULL) OR (e.date_official_start IS NOT NULL))) THEN 'active'::text
            ELSE 'unknown'::text
        END AS status
   FROM (((((((((((((((((public.employees e
     LEFT JOIN public.enum_lookup nat ON ((e.nationality_id = nat.id)))
     LEFT JOIN public.enum_lookup occ ON ((e.occupation_id = occ.id)))
     LEFT JOIN public.enum_lookup rel ON ((e.religion_id = rel.id)))
     LEFT JOIN public.enum_lookup eth ON ((e.ethnicity_id = eth.id)))
     LEFT JOIN public.districts td ON ((e.temporary_district_id = td.id)))
     LEFT JOIN public.provinces tp ON ((td.province_id = tp.id)))
     LEFT JOIN public.districts pd ON ((e.permanent_district_id = pd.id)))
     LEFT JOIN public.provinces pp ON ((pd.province_id = pp.id)))
     LEFT JOIN public.job_titles jt ON ((e.job_title_id = jt.id)))
     LEFT JOIN public.organizations org ON ((e.organization_id = org.id)))
     LEFT JOIN public.locations wl ON ((e.work_location_id = wl.id)))
     LEFT JOIN public.enum_lookup pi ON ((e.place_issue_id = pi.id)))
     LEFT JOIN public.enum_lookup en ON ((e.en_cert_id = en.id)))
     LEFT JOIN public.enum_lookup it ON ((e.it_cert_id = it.id)))
     LEFT JOIN public.provinces hp ON ((e.hometown_provinces_id = hp.id)))
     LEFT JOIN public.employees mng ON ((e.manager_id = mng.id)))
     LEFT JOIN public.enum_lookup job_change_lookup ON (((e.job_change_type)::text = (job_change_lookup.value)::text)));


ALTER VIEW public.employees_export_full_view OWNER TO postgres;

--
-- Name: employees_export_full_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_export_full_view_id_seq
    START WITH 9222
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_export_full_view_id_seq OWNER TO postgres;

--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.employees ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: entity_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entity_permission (
    entity_id integer NOT NULL,
    entity_type character varying(100) NOT NULL,
    role_id integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.entity_permission OWNER TO postgres;

--
-- Name: entity_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.entity_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.entity_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: enum_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.enum_category_id_seq
    START WITH 21
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enum_category_id_seq OWNER TO postgres;

--
-- Name: enum_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enum_category (
    id integer DEFAULT nextval('public.enum_category_id_seq'::regclass) NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT enum_category_code_check CHECK (((length(TRIM(BOTH FROM code)) >= 1) AND (length(TRIM(BOTH FROM code)) <= 50))),
    CONSTRAINT enum_category_is_active_check CHECK ((is_active = ANY (ARRAY[true, false]))),
    CONSTRAINT enum_category_name_check CHECK (((length(TRIM(BOTH FROM name)) >= 1) AND (length(TRIM(BOTH FROM name)) <= 100))),
    CONSTRAINT enum_category_sort_order_check CHECK ((sort_order >= 0))
);


ALTER TABLE public.enum_category OWNER TO postgres;

--
-- Name: external_experiences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.external_experiences_id_seq
    START WITH 16664
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.external_experiences_id_seq OWNER TO postgres;

--
-- Name: external_experiences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.external_experiences (
    id integer DEFAULT nextval('public.external_experiences_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    "position" text,
    company_name character varying(100),
    address character varying(200),
    start_date date,
    end_date date,
    start_salary numeric(15,2),
    current_salary numeric(15,2),
    phone character varying(30),
    contact character varying(100),
    contact_position character varying(50),
    main_duty text,
    reason_leave text,
    note text
);


ALTER TABLE public.external_experiences OWNER TO postgres;

--
-- Name: family_dependents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.family_dependents_id_seq
    START WITH 40836
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.family_dependents_id_seq OWNER TO postgres;

--
-- Name: family_dependents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.family_dependents (
    id integer DEFAULT nextval('public.family_dependents_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    full_name text NOT NULL,
    gender public.gender,
    address text,
    phone text,
    email text,
    identity_no text,
    identity_type text DEFAULT 'CCCD'::text NOT NULL,
    tax_no text,
    is_tax_dependent boolean DEFAULT false NOT NULL,
    occupation text,
    workplace text,
    before_1975 text,
    after_1975 text,
    note text,
    is_alive boolean DEFAULT true NOT NULL,
    relationship_type_id integer NOT NULL,
    relative_emp_id integer,
    is_dependent boolean DEFAULT false NOT NULL,
    reason text,
    deduction_start_date date,
    deduction_end_date date,
    created_at timestamp with time zone,
    created_by text,
    modified_at timestamp with time zone,
    modified_by text,
    dob integer,
    CONSTRAINT dob_4_digits CHECK (((dob >= 1000) AND (dob <= 9999)))
);


ALTER TABLE public.family_dependents OWNER TO postgres;

--
-- Name: feature_action_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.feature_action_id_seq
    START WITH 138
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.feature_action_id_seq OWNER TO postgres;

--
-- Name: feature_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.feature_action (
    id integer DEFAULT nextval('public.feature_action_id_seq'::regclass) NOT NULL,
    feature_id integer NOT NULL,
    action_id integer NOT NULL
);


ALTER TABLE public.feature_action OWNER TO postgres;

--
-- Name: features_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.features_id_seq
    START WITH 63
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.features_id_seq OWNER TO postgres;

--
-- Name: features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.features (
    id integer DEFAULT nextval('public.features_id_seq'::regclass) NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    parent_id integer,
    is_active boolean DEFAULT true
);


ALTER TABLE public.features OWNER TO postgres;

--
-- Name: feature_action_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.feature_action_view AS
 SELECT fa.id,
    fa.feature_id,
    f.name AS feature_name,
    fa.action_id,
    a.code AS action_code,
    a.name AS action_name
   FROM ((public.feature_action fa
     LEFT JOIN public.features f ON ((fa.feature_id = f.id)))
     LEFT JOIN public.actions a ON ((fa.action_id = a.id)));


ALTER VIEW public.feature_action_view OWNER TO postgres;

--
-- Name: feature_action_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.feature_action_view_id_seq
    START WITH 138
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.feature_action_view_id_seq OWNER TO postgres;

--
-- Name: form_definition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_definition (
    id uuid NOT NULL,
    code character varying(255) NOT NULL,
    description character varying(255),
    json_schema jsonb,
    name character varying(255) NOT NULL
);


ALTER TABLE public.form_definition OWNER TO postgres;

--
-- Name: grid_definition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grid_definition (
    id uuid NOT NULL,
    column_def jsonb,
    default_sort character varying(50),
    report_code character varying(50) NOT NULL
);


ALTER TABLE public.grid_definition OWNER TO postgres;

--
-- Name: job_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_assignments_id_seq OWNER TO postgres;

--
-- Name: job_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_assignments (
    id integer DEFAULT nextval('public.job_assignments_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    job_title_id integer NOT NULL,
    org_id integer,
    cost_center_id integer,
    start_date date NOT NULL,
    end_date date,
    is_active boolean DEFAULT true,
    description text
);


ALTER TABLE public.job_assignments OWNER TO postgres;

--
-- Name: job_grades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_grades_id_seq OWNER TO postgres;

--
-- Name: job_grades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_grades (
    id integer DEFAULT nextval('public.job_grades_id_seq'::regclass) NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(50) NOT NULL,
    en_name character varying(50),
    CONSTRAINT check_job_grade_level CHECK ((level >= 0)),
    CONSTRAINT chk_job_grade_code_not_empty CHECK ((TRIM(BOTH FROM code) <> ''::text)),
    CONSTRAINT chk_job_grade_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);


ALTER TABLE public.job_grades OWNER TO postgres;

--
-- Name: job_grades_unique_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.job_grades_unique_view AS
 SELECT DISTINCT ON (name) id,
    name,
    en_name
   FROM public.job_grades
  ORDER BY name, id;


ALTER VIEW public.job_grades_unique_view OWNER TO postgres;

--
-- Name: job_grades_unique_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_grades_unique_view_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_grades_unique_view_id_seq OWNER TO postgres;

--
-- Name: job_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_groups_id_seq
    START WITH 4
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_groups_id_seq OWNER TO postgres;

--
-- Name: job_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_groups (
    id integer DEFAULT nextval('public.job_groups_id_seq'::regclass) NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    en_name character varying(100),
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0 NOT NULL,
    description text
);


ALTER TABLE public.job_groups OWNER TO postgres;

--
-- Name: job_title_organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_title_organizations_id_seq
    START WITH 11062
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_title_organizations_id_seq OWNER TO postgres;

--
-- Name: job_title_organizations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_title_organizations (
    id integer DEFAULT nextval('public.job_title_organizations_id_seq'::regclass) NOT NULL,
    job_title_id integer NOT NULL,
    org_id integer,
    staff_allocation integer,
    note text,
    is_active boolean DEFAULT true NOT NULL,
    job_desc text,
    job_position_name character varying
);


ALTER TABLE public.job_title_organizations OWNER TO postgres;

--
-- Name: COLUMN job_title_organizations.job_position_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.job_title_organizations.job_position_name IS 'Tên vị trí công việc';


--
-- Name: job_title_detail_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.job_title_detail_view AS
 SELECT jt.id,
    jt.name AS job_title_name,
    jt.is_active AS status,
    jt.is_management AS is_manager,
    jt.grade_id,
    jt.group_id,
    jt.code AS job_title_code,
    jt.en_name AS job_title_en_name,
    jg.code AS job_grade_code,
    jg.name AS job_grade_name,
    jg.level AS job_grade_level,
    o.name AS organization_name,
    cc.name AS cost_center_name,
    jt.description AS job_title_description,
    jt.sort_order AS job_title_sort_order,
    jg2.name AS job_group_name,
    jt.parent_id,
    parent_jt.name AS parent_name
   FROM ((((((public.job_titles jt
     LEFT JOIN public.job_grades jg ON ((jt.grade_id = jg.id)))
     LEFT JOIN public.job_title_organizations jto ON ((jt.id = jto.job_title_id)))
     LEFT JOIN public.organizations o ON ((jto.org_id = o.id)))
     LEFT JOIN public.cost_centers cc ON ((o.cost_centers_id = cc.id)))
     LEFT JOIN public.job_groups jg2 ON ((jg2.id = jt.group_id)))
     LEFT JOIN public.job_titles parent_jt ON ((jt.parent_id = parent_jt.id)));


ALTER VIEW public.job_title_detail_view OWNER TO postgres;

--
-- Name: job_title_detail_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_title_detail_view_id_seq
    START WITH 1564
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_title_detail_view_id_seq OWNER TO postgres;

--
-- Name: job_titles_list_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.job_titles_list_view AS
 SELECT jt.id AS job_title_id,
    jt.code AS job_title_code,
    jt.name AS job_title_name,
    jt.en_name AS job_title_en_name,
    jt.foreign_name AS job_title_foreign_name,
    jg.code AS job_grade_code,
    jg.name AS job_grade_name,
    jg.level AS job_grade_level,
    jg2.name AS job_group_name,
    jt.cost_center_id,
    cc.name AS cost_center_name,
    jt.description AS job_title_description,
    jt.sort_order AS job_title_sort_order,
    jt.is_active AS status,
    jt.is_management AS is_manager,
    jt.grade_id,
    jt.group_id,
    jt.parent_id,
    parent_jt.name AS parent_name,
    COALESCE(emp_count.total_employees, (0)::bigint) AS total_employees
   FROM (((((public.job_titles jt
     LEFT JOIN public.job_grades jg ON ((jt.grade_id = jg.id)))
     LEFT JOIN public.job_groups jg2 ON ((jt.group_id = jg2.id)))
     LEFT JOIN public.job_titles parent_jt ON ((jt.parent_id = parent_jt.id)))
     LEFT JOIN public.cost_centers cc ON ((jt.cost_center_id = cc.id)))
     LEFT JOIN ( SELECT employees.job_title_id,
            count(*) AS total_employees
           FROM public.employees
          GROUP BY employees.job_title_id) emp_count ON ((jt.id = emp_count.job_title_id)))
  ORDER BY jt.sort_order, jt.name;


ALTER VIEW public.job_titles_list_view OWNER TO postgres;

--
-- Name: list_emp_by_job_title_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.list_emp_by_job_title_view AS
 SELECT e.id,
    e.emp_code,
    e.full_name,
    e.gender,
    e.job_title_id,
    jt.name AS job_title_name,
    e.organization_id,
    o.name AS organization_name
   FROM ((public.employees e
     JOIN public.job_titles jt ON ((e.job_title_id = jt.id)))
     JOIN public.organizations o ON ((e.organization_id = o.id)))
  WHERE (e.date_resign IS NULL);


ALTER VIEW public.list_emp_by_job_title_view OWNER TO postgres;

--
-- Name: list_emp_by_job_title_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.list_emp_by_job_title_view_id_seq
    START WITH 9222
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.list_emp_by_job_title_view_id_seq OWNER TO postgres;

--
-- Name: org_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.org_log_id_seq
    START WITH 2117
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.org_log_id_seq OWNER TO postgres;

--
-- Name: org_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_log (
    id integer DEFAULT nextval('public.org_log_id_seq'::regclass) NOT NULL,
    org_id integer NOT NULL,
    target_org_id integer,
    action character varying(50) NOT NULL,
    reason text,
    log_date timestamp without time zone DEFAULT now(),
    code character varying(10),
    name character varying(255) NOT NULL,
    en_name character varying(255),
    category_id integer,
    parent_org_id integer,
    location_id integer,
    phone character varying(30),
    email character varying(50),
    effective_date date,
    expired_date date,
    cost_centers_id integer,
    is_active boolean NOT NULL,
    approve_struct character varying(255),
    decision_no character varying(30),
    decision_date date,
    description text,
    version integer,
    created_at timestamp with time zone,
    created_by text,
    modified_at timestamp with time zone,
    modified_by text,
    general_manager_id integer,
    direct_manager_id integer
);


ALTER TABLE public.org_log OWNER TO postgres;

--
-- Name: org_log_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.org_log_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.org_log_attachment_id_seq OWNER TO postgres;

--
-- Name: org_log_attachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_log_attachment (
    id integer DEFAULT nextval('public.org_log_attachment_id_seq'::regclass) NOT NULL,
    log_id integer NOT NULL,
    attachment_id integer NOT NULL
);


ALTER TABLE public.org_log_attachment OWNER TO postgres;

--
-- Name: org_log_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.org_log_detail_id_seq
    START WITH 3
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.org_log_detail_id_seq OWNER TO postgres;

--
-- Name: org_log_detail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_log_detail (
    id integer DEFAULT nextval('public.org_log_detail_id_seq'::regclass) NOT NULL,
    org_log_id integer NOT NULL,
    target_org_id integer NOT NULL
);


ALTER TABLE public.org_log_detail OWNER TO postgres;

--
-- Name: COLUMN org_log_detail.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.org_log_detail.id IS 'ID của bản ghi chi tiết';


--
-- Name: COLUMN org_log_detail.org_log_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.org_log_detail.org_log_id IS 'Liên kết với bảng org_log để xác định sự kiện thay đổi';


--
-- Name: COLUMN org_log_detail.target_org_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.org_log_detail.target_org_id IS 'ID của tổ chức mới sau khi chia tách';


--
-- Name: organization_details_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.organization_details_view AS
 SELECT o.id,
    o.code,
    o.name,
    o.en_name,
    o.parent_org_id,
    o.location_id,
    o.email,
    parent.name AS parent_name,
    l.name AS location_name,
    l.address,
    d.name AS districts_name,
    p.name AS provinces_name,
    o.phone,
    o.effective_date,
    o.expired_date,
    e.value AS code_category,
    e.name AS category_name,
    e.id AS category_id,
    o.description,
    o.is_active,
    o.decision_no,
    o.decision_date,
    (o.approve_struct)::text AS approve_struct,
    cc.id AS cost_center_id,
    cc.name AS cost_center_name,
    o.general_manager_id,
    gm.full_name AS general_manager_name,
    o.direct_manager_id,
    dm.full_name AS direct_manager_name,
    ( SELECT count(*) AS count
           FROM public.organizations sub_org
          WHERE ((sub_org.parent_org_id = o.id) AND sub_org.is_active)) AS sub_org_count
   FROM ((((((((public.organizations o
     LEFT JOIN public.organizations parent ON ((o.parent_org_id = parent.id)))
     LEFT JOIN public.enum_lookup e ON ((o.category_id = e.id)))
     LEFT JOIN public.locations l ON ((o.location_id = l.id)))
     LEFT JOIN public.districts d ON ((l.districts_id = d.id)))
     LEFT JOIN public.provinces p ON ((d.province_id = p.id)))
     LEFT JOIN public.cost_centers cc ON ((o.cost_centers_id = cc.id)))
     LEFT JOIN public.employees gm ON ((o.general_manager_id = gm.id)))
     LEFT JOIN public.employees dm ON ((o.direct_manager_id = dm.id)));


ALTER VIEW public.organization_details_view OWNER TO postgres;

--
-- Name: organization_details_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.organization_details_view_id_seq
    START WITH 2110
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organization_details_view_id_seq OWNER TO postgres;

--
-- Name: organization_documents_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.organization_documents_view AS
 SELECT DISTINCT ol.id AS org_log_id,
    ol.org_id AS organization_id,
    ol.log_date,
        CASE
            WHEN ((ol.action)::text = 'UPDATE'::text) THEN 'Điều chỉnh'::character varying
            WHEN ((ol.action)::text = 'CREATE'::text) THEN 'Thành lập'::character varying
            WHEN ((ol.action)::text = 'DELETE'::text) THEN 'Xóa'::character varying
            WHEN ((ol.action)::text = 'DISSOLVE'::text) THEN 'Giải thể'::character varying
            WHEN ((ol.action)::text = 'MERGED'::text) THEN 'Sáp nhập'::character varying
            WHEN ((ol.action)::text = 'UPDATE AFTER MERGER'::text) THEN 'Sáp nhập'::character varying
            WHEN ((ol.action)::text = 'UPDATED PARENT'::text) THEN 'Sáp nhập'::character varying
            WHEN ((ol.action)::text = 'SPLIT PARENT'::text) THEN 'Chia tách'::character varying
            WHEN ((ol.action)::text = 'UPDATE AFTER SPLIT'::text) THEN 'Chia tách'::character varying
            ELSE ol.action
        END AS document_type,
    ol.effective_date AS issued_date,
    a.file_url,
    a.file_name AS document_name,
    a.file_size,
    al.type,
    ol.version
   FROM (((public.org_log ol
     JOIN public.org_log_attachment ola ON ((ola.log_id = ol.id)))
     JOIN public.attachments a ON ((a.id = ola.attachment_id)))
     JOIN public.attachment_link al ON ((al.attachment_id = a.id)))
  WHERE (a.file_name IS NOT NULL);


ALTER VIEW public.organization_documents_view OWNER TO postgres;

--
-- Name: passports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.passports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.passports_id_seq OWNER TO postgres;

--
-- Name: passports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.passports (
    id integer DEFAULT nextval('public.passports_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    passport_no character(30) NOT NULL,
    type character(30) NOT NULL,
    date_issue date NOT NULL,
    expired_date date,
    place_issue character varying(100) NOT NULL
);


ALTER TABLE public.passports OWNER TO postgres;

--
-- Name: positions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.positions AS
 SELECT jto.id,
    jto.org_id,
    o.code AS org_code,
    o.name AS org_name,
    o.en_name AS org_en_name,
    o.parent_org_id,
    po.name AS parent_org_name,
    jto.job_title_id,
    jt.name AS title_name,
    jt.en_name AS title_en_name,
    jt.grade_id,
    jt.group_id,
    jt.sort_order,
    jto.job_position_name AS position_name,
    jto.staff_allocation,
    jto.note,
    jto.is_active,
    COALESCE(jto.job_desc, jt.description) AS job_desc,
    count(DISTINCT
        CASE
            WHEN ((e.date_join IS NOT NULL) AND (e.date_resign IS NULL)) THEN e.id
            ELSE NULL::integer
        END) AS current_staff,
        CASE
            WHEN (count(DISTINCT
            CASE
                WHEN ((e.date_join IS NOT NULL) AND (e.date_resign IS NULL)) THEN e.id
                ELSE NULL::integer
            END) > jto.staff_allocation) THEN 'Overstaffed'::text
            WHEN (count(DISTINCT
            CASE
                WHEN ((e.date_join IS NOT NULL) AND (e.date_resign IS NULL)) THEN e.id
                ELSE NULL::integer
            END) = jto.staff_allocation) THEN 'Adequate'::text
            ELSE 'Understaffed'::text
        END AS staffing_status
   FROM ((((public.job_title_organizations jto
     JOIN public.organizations o ON ((jto.org_id = o.id)))
     LEFT JOIN public.organizations po ON ((o.parent_org_id = po.id)))
     JOIN public.job_titles jt ON ((jto.job_title_id = jt.id)))
     LEFT JOIN ( SELECT employees.id,
            employees.job_title_id,
            employees.organization_id,
            employees.date_join,
            employees.date_resign
           FROM public.employees
          WHERE ((employees.date_join IS NOT NULL) AND (employees.date_resign IS NULL))) e ON (((e.job_title_id = jto.job_title_id) AND (e.organization_id = jto.org_id))))
  GROUP BY jto.id, jto.org_id, o.code, o.name, o.en_name, o.parent_org_id, po.name, jto.job_title_id, jt.name, jt.en_name, jt.grade_id, jt.group_id, jt.sort_order, jto.job_position_name, jto.staff_allocation, jto.note, jto.is_active, jto.job_desc, jt.description;


ALTER VIEW public.positions OWNER TO postgres;

--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.positions_id_seq
    START WITH 11062
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.positions_id_seq OWNER TO postgres;

--
-- Name: project_members_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_members_id_seq OWNER TO postgres;

--
-- Name: project_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_members (
    id integer DEFAULT nextval('public.project_members_id_seq'::regclass) NOT NULL,
    project_id integer NOT NULL,
    emp_id integer NOT NULL,
    role character varying(50) NOT NULL,
    main_tasks text,
    join_date date NOT NULL,
    exit_date date,
    note text
);


ALTER TABLE public.project_members OWNER TO postgres;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_id_seq OWNER TO postgres;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer DEFAULT nextval('public.projects_id_seq'::regclass) NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(255) NOT NULL,
    en_name character varying(255),
    start_date date NOT NULL,
    end_date date,
    status public.projectstatus DEFAULT 'SPENDING'::public.projectstatus NOT NULL,
    description text,
    note text
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: relationship_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.relationship_types_id_seq
    START WITH 264
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.relationship_types_id_seq OWNER TO postgres;

--
-- Name: relationship_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relationship_types (
    id integer DEFAULT nextval('public.relationship_types_id_seq'::regclass) NOT NULL,
    code character varying(30) NOT NULL,
    en_name character varying(30),
    name character varying(30) NOT NULL
);


ALTER TABLE public.relationship_types OWNER TO postgres;

--
-- Name: report_audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_audit_log (
    id uuid NOT NULL,
    duration_ms integer,
    error_message character varying(255),
    executed_at timestamp without time zone,
    filter_params jsonb,
    report_code character varying(50) NOT NULL,
    result_summary jsonb,
    success boolean,
    tenant_id character varying(50),
    user_id character varying(50)
);


ALTER TABLE public.report_audit_log OWNER TO postgres;

--
-- Name: report_definition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_definition (
    id uuid NOT NULL,
    code character varying(255) NOT NULL,
    filter_form_code character varying(50),
    is_active boolean,
    name character varying(255) NOT NULL,
    output_file_prefix character varying(50),
    sp_name character varying(255),
    template_file_path character varying(255),
    parent_id uuid NOT NULL,
    group_name character varying(255)
);


ALTER TABLE public.report_definition OWNER TO postgres;

--
-- Name: report_export_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_export_log (
    id uuid NOT NULL,
    duration_ms integer,
    exported_at timestamp without time zone,
    file_path character varying(255),
    params_json jsonb,
    record_count integer,
    report_code character varying(50) NOT NULL,
    tenant_id character varying(50),
    user_id character varying(50)
);


ALTER TABLE public.report_export_log OWNER TO postgres;

--
-- Name: report_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_group (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_name text NOT NULL,
    module text NOT NULL
);


ALTER TABLE public.report_group OWNER TO postgres;

--
-- Name: result; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.result (
    jsonb_build_object jsonb
);


ALTER TABLE public.result OWNER TO postgres;

--
-- Name: reward_disciplinary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reward_disciplinary_id_seq
    START WITH 30946
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reward_disciplinary_id_seq OWNER TO postgres;

--
-- Name: reward_disciplinary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reward_disciplinary (
    id integer DEFAULT nextval('public.reward_disciplinary_id_seq'::regclass) NOT NULL,
    emp_id integer NOT NULL,
    decision_no character varying(50) NOT NULL,
    type_reward_id integer,
    issuer character varying(100),
    issuer_position character varying(100),
    decision_date date NOT NULL,
    start_date date NOT NULL,
    end_date date,
    note text,
    type public.rewarddisciplinarytype NOT NULL,
    form integer,
    reason text,
    decision_authority_name text,
    achievement text
);


ALTER TABLE public.reward_disciplinary OWNER TO postgres;

--
-- Name: COLUMN reward_disciplinary.achievement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reward_disciplinary.achievement IS 'Thành tích';


--
-- Name: reward_disciplinary_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reward_disciplinary_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reward_disciplinary_types_id_seq OWNER TO postgres;

--
-- Name: reward_disciplinary_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reward_disciplinary_types (
    id integer DEFAULT nextval('public.reward_disciplinary_types_id_seq'::regclass) NOT NULL,
    type text NOT NULL,
    category public.decisioncategory NOT NULL,
    exemplary_level public.exemplarylevel NOT NULL,
    reason text NOT NULL,
    description text
);


ALTER TABLE public.reward_disciplinary_types OWNER TO postgres;

--
-- Name: reward_disciplinary_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.reward_disciplinary_view AS
 SELECT rd.id,
    rd.emp_id,
    (rd.type)::text AS type,
    rd.issuer,
    rd.issuer_position,
    rd.decision_no,
    rd.type_reward_id,
    da.name AS type_reward_name,
    rd.decision_authority_name,
    rd.reason,
    rd.note,
    to_char((rd.decision_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS decision_date,
    to_char((rd.start_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS start_date,
    to_char((rd.end_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS end_date,
    rd.form AS form_id,
    f.name AS form_name,
    rd.achievement
   FROM ((public.reward_disciplinary rd
     LEFT JOIN public.enum_lookup da ON ((rd.type_reward_id = da.id)))
     LEFT JOIN public.enum_lookup f ON ((rd.form = f.id)));


ALTER VIEW public.reward_disciplinary_view OWNER TO postgres;

--
-- Name: reward_disciplinary_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reward_disciplinary_view_id_seq
    START WITH 30946
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reward_disciplinary_view_id_seq OWNER TO postgres;

--
-- Name: role_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_permission_id_seq
    START WITH 428
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permission_id_seq OWNER TO postgres;

--
-- Name: role_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permission (
    id integer DEFAULT nextval('public.role_permission_id_seq'::regclass) NOT NULL,
    role_id integer NOT NULL,
    feature_id integer NOT NULL,
    action_id integer NOT NULL,
    scope public.permission_scope DEFAULT 'ALL'::public.permission_scope
);


ALTER TABLE public.role_permission OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 13
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer DEFAULT nextval('public.roles_id_seq'::regclass) NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: role_permission_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.role_permission_view AS
 SELECT rp.id,
    rp.role_id,
    r.name AS role_name,
    rp.feature_id,
    f.name AS feature_name,
    rp.action_id,
    a.name AS action_name,
    a.code AS action_code,
    rp.scope
   FROM (((public.role_permission rp
     LEFT JOIN public.features f ON ((rp.feature_id = f.id)))
     LEFT JOIN public.actions a ON ((rp.action_id = a.id)))
     LEFT JOIN public.roles r ON ((rp.role_id = r.id)));


ALTER VIEW public.role_permission_view OWNER TO postgres;

--
-- Name: role_permission_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_permission_view_id_seq
    START WITH 428
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permission_view_id_seq OWNER TO postgres;

--
-- Name: user_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_role (
    user_id uuid NOT NULL,
    role_id integer NOT NULL
);


ALTER TABLE public.user_role OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    name character varying(100),
    preferred_username text,
    email text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: v_degree_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.v_degree_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.v_degree_info_id_seq OWNER TO postgres;

--
-- Name: v_degree_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.v_degree_info (
    id integer DEFAULT nextval('public.v_degree_info_id_seq'::regclass),
    emp_id integer,
    is_main boolean,
    type character varying(50),
    degree_no character varying(30),
    academic character varying(30),
    institution character varying(255),
    classification character varying(30),
    faculty character varying(50),
    major character varying(255),
    education_mode character varying(50),
    start_date date,
    end_date date,
    graduation_year date,
    training_location character varying(30),
    note character varying(255)
);


ALTER TABLE public.v_degree_info OWNER TO postgres;

--
-- Name: v_job_title_by_org; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_job_title_by_org AS
 SELECT o.id AS org_id,
    o.code AS org_code,
    o.name AS org_name,
    o.category_id,
    el.name AS category_name,
    el.value AS category_value,
    jto.id AS job_title_org_id,
    jt.id AS job_title_id,
    jt.code AS job_title_code,
    jt.name AS job_title_name,
    jt.en_name AS job_title_en_name,
    jg.name AS job_group_name,
    jgr.name AS job_grade_name,
    jto.staff_allocation,
    jto.job_position_name,
    jto.job_desc,
    jto.note,
    jto.is_active,
    count(e.id) AS current_employee_count
   FROM ((((((public.organizations o
     LEFT JOIN public.enum_lookup el ON ((o.category_id = el.id)))
     LEFT JOIN public.job_title_organizations jto ON ((o.id = jto.org_id)))
     LEFT JOIN public.job_titles jt ON ((jto.job_title_id = jt.id)))
     LEFT JOIN public.job_groups jg ON ((jt.group_id = jg.id)))
     LEFT JOIN public.job_grades jgr ON ((jt.grade_id = jgr.id)))
     LEFT JOIN public.employees e ON (((e.organization_id = o.id) AND (e.job_title_id = jt.id) AND ((e.date_resign IS NULL) OR (e.date_resign > CURRENT_DATE)))))
  WHERE (o.is_active = true)
  GROUP BY o.id, o.code, o.name, o.category_id, el.name, el.value, jto.id, jt.id, jt.code, jt.name, jt.en_name, jg.name, jgr.name, jto.staff_allocation, jto.job_position_name, jto.job_desc, jto.note, jto.is_active;


ALTER VIEW public.v_job_title_by_org OWNER TO postgres;

--
-- Name: v_role_feature_actions_ac; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_role_feature_actions_ac AS
 WITH feature_actions AS (
         SELECT rp.role_id,
            f.id AS feature_id,
            f.name AS feature_name,
            json_agg(json_build_object('action_id', a.id, 'action_name', a.name, 'action_code', a.code) ORDER BY a.id) AS actions
           FROM ((public.role_permission rp
             JOIN public.features f ON ((rp.feature_id = f.id)))
             JOIN public.actions a ON ((rp.action_id = a.id)))
          GROUP BY rp.role_id, f.id, f.name
        )
 SELECT fa.role_id,
    r.name AS role_name,
    json_agg(json_build_object('feature_id', fa.feature_id, 'feature_name', fa.feature_name, 'actions', fa.actions) ORDER BY fa.feature_id) AS features
   FROM (feature_actions fa
     JOIN public.roles r ON ((fa.role_id = r.id)))
  GROUP BY fa.role_id, r.name;


ALTER VIEW public.v_role_feature_actions_ac OWNER TO postgres;

--
-- Name: vw_export_employees_full_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vw_export_employees_full_id_seq
    START WITH 9222
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vw_export_employees_full_id_seq OWNER TO postgres;

--
-- Name: work_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.work_histories_id_seq
    START WITH 45917
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.work_histories_id_seq OWNER TO postgres;

--
-- Name: work_histories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_histories (
    id integer DEFAULT nextval('public.work_histories_id_seq'::regclass) NOT NULL,
    emp_id integer,
    job_title_id integer,
    organization_id integer,
    change_type_id integer,
    decision_no character varying(50),
    decision_signer text,
    decision_sign_date date,
    start_date date NOT NULL,
    end_date date,
    reason text,
    note character varying(255),
    work_place text,
    organization_name text,
    job_title_name text
);


ALTER TABLE public.work_histories OWNER TO postgres;

--
-- Name: work_histories_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.work_histories_view AS
 WITH RECURSIVE org_hierarchy AS (
         SELECT o.id,
            o.name,
            o.parent_org_id,
            o.category_id,
            o.id AS origin_org_id
           FROM public.organizations o
        UNION ALL
         SELECT parent.id,
            parent.name,
            parent.parent_org_id,
            parent.category_id,
            child.origin_org_id
           FROM (public.organizations parent
             JOIN org_hierarchy child ON ((parent.id = child.parent_org_id)))
        ), target_parent_orgs AS (
         SELECT DISTINCT ON (oh.origin_org_id) oh.origin_org_id,
            oh.name AS target_name
           FROM (org_hierarchy oh
             JOIN public.enum_lookup el ON ((oh.category_id = el.id)))
          WHERE ((el.value)::text = ANY (ARRAY[('O12'::character varying)::text, ('O175'::character varying)::text]))
          ORDER BY oh.origin_org_id, oh.id
        )
 SELECT wh.emp_id,
    (wh.job_title_id)::text AS job_title_id,
    (wh.organization_id)::text AS organization_id,
    tpo.target_name AS organization_parent_name,
    (wh.change_type_id)::text AS change_type_id,
    ct.name AS change_type_name,
    wh.decision_no,
    wh.decision_signer,
    wh.organization_name,
    wh.job_title_name,
    wh.work_place,
    to_char((wh.decision_sign_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS decision_sign_date,
    to_char((wh.start_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS start_date,
    to_char((wh.end_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS end_date,
    to_char((e.date_join)::timestamp with time zone, 'YYYY-MM-DD'::text) AS date_join,
    to_char((e.date_official_start)::timestamp with time zone, 'YYYY-MM-DD'::text) AS date_official_start,
    wh.reason,
    wh.note,
    e.manager_id,
    m.full_name AS manager_name,
    org.general_manager_id,
    org.direct_manager_id,
    gm.full_name AS general_manager_name,
    dm.full_name AS direct_manager_name,
        CASE
            WHEN (wh.end_date IS NULL) THEN NULL::integer
            ELSE (round(((EXTRACT(year FROM age((wh.end_date)::timestamp with time zone, (wh.start_date)::timestamp with time zone)) * (12)::numeric) + EXTRACT(month FROM age((wh.end_date)::timestamp with time zone, (wh.start_date)::timestamp with time zone)))))::integer
        END AS total_month
   FROM ((((((((public.work_histories wh
     LEFT JOIN public.employees e ON ((wh.emp_id = e.id)))
     LEFT JOIN public.employees m ON ((e.manager_id = m.id)))
     LEFT JOIN public.job_titles jt ON ((wh.job_title_id = jt.id)))
     LEFT JOIN public.organizations org ON ((wh.organization_id = org.id)))
     LEFT JOIN target_parent_orgs tpo ON ((org.id = tpo.origin_org_id)))
     LEFT JOIN public.employees gm ON ((org.general_manager_id = gm.id)))
     LEFT JOIN public.employees dm ON ((org.direct_manager_id = dm.id)))
     LEFT JOIN public.enum_lookup ct ON ((wh.change_type_id = ct.id)));


ALTER VIEW public.work_histories_view OWNER TO postgres;

--
-- Name: attachment_files_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachment_files_view ALTER COLUMN id SET DEFAULT nextval('public.attachment_files_view_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: employee_list_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_list_view ALTER COLUMN id SET DEFAULT nextval('public.employee_list_view_id_seq'::regclass);


--
-- Name: feature_action_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feature_action_view ALTER COLUMN id SET DEFAULT nextval('public.feature_action_view_id_seq'::regclass);


--
-- Name: job_grades_unique_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_grades_unique_view ALTER COLUMN id SET DEFAULT nextval('public.job_grades_unique_view_id_seq'::regclass);


--
-- Name: job_title_detail_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_title_detail_view ALTER COLUMN id SET DEFAULT nextval('public.job_title_detail_view_id_seq'::regclass);


--
-- Name: list_emp_by_job_title_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.list_emp_by_job_title_view ALTER COLUMN id SET DEFAULT nextval('public.list_emp_by_job_title_view_id_seq'::regclass);


--
-- Name: organization_details_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organization_details_view ALTER COLUMN id SET DEFAULT nextval('public.organization_details_view_id_seq'::regclass);


--
-- Name: reward_disciplinary_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_disciplinary_view ALTER COLUMN id SET DEFAULT nextval('public.reward_disciplinary_view_id_seq'::regclass);


--
-- Name: role_permission_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permission_view ALTER COLUMN id SET DEFAULT nextval('public.role_permission_view_id_seq'::regclass);


--
-- Data for Name: abroad_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.abroad_records (id, emp_id, start_date, end_date, national_id, visas_no, type, place_issue, reason, note) FROM stdin;
\.


--
-- Data for Name: actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.actions (id, code, name, description, is_active) FROM stdin;
\.


--
-- Data for Name: attachment_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attachment_link (id, attachment_id, target_table, target_id, note, created_at, type, modified_at) FROM stdin;
\.


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attachments (id, file_url, file_name, file_type, file_size, created_at, modified_at, created_by, modified_by) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, table_name, operation, record_id, old_data, new_data, reason, changed_at, changed_by, actor_name, actor_role, realm_roles, session_id, request_id, tenant_schema, client_ip) FROM stdin;
\.


--
-- Data for Name: certificates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.certificates (id, emp_id, type_id, cert_no, name, issued_by, date_issue, expired_date, note) FROM stdin;
\.


--
-- Data for Name: cost_centers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cost_centers (id, code, name, en_name, budget_allocated, budget_used, is_active) FROM stdin;
\.


--
-- Data for Name: degrees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.degrees (id, emp_id, is_main, type, degree_no, academic, institution, classification, faculty, major, education_mode, start_date, end_date, graduation_year, training_location, note) FROM stdin;
\.


--
-- Data for Name: districts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.districts (id, province_id, name, en_name, note, is_active, description) FROM stdin;
\.


--
-- Data for Name: employee_health; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee_health (id, emp_id, examination_date, hospital, examiner, health_evaluate, health_status, doctor_recommend, note) FROM stdin;
\.


--
-- Data for Name: employee_histories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee_histories (id, emp_id, action, log_date, emp_code, emp_code_old, nationality_id, enum_info, last_name, middle_name, first_name, full_name, gender, temporary_address, temporary_district_id, hometown_provinces_id, permanent_address, permanent_district_id, email_internal, email_external, phone, secondary_phone, home_phone, company_phone, marital_status, education_level, profile_introduced, job_title_id, organization_id, work_location_id, avatar, note, old_identity_no, old_date_issue, old_place_issue_id, identity_type, identity_no, date_issue, date_identity_expiry, place_issue_id, date_join, date_probation_start, date_official_start, date_resign, last_work_date, blood_group, blood_pressure, height_cm, weight_kg, job_change_type, manager_id, decision_no, decision_signer, decision_sign_date, start_date_change, end_date_change, work_note, tax_no, cif_code, bank_account_no, bank_name, is_social_insurance, is_unemployment_insurance, is_life_insurance, party_start_date, party_official_date, military_start_date, military_end_date, military_highest_rank, is_old_regime, is_wounded_soldier, en_cert_id, it_cert_id, degree_type, academic, institution, faculty, major, graduation_year, degree_info, certif_info, rewards_discipline, external_work, family_relationships, employee_type, log_type, created_at, created_by, modified_at, modified_by, internal_working, dob, recruitment, certificate_name, union_youth_start_date, union_start_date, union_fee_date, union_decision_no, union_decision_date, union_appointment_no, union_position, union_organization_name, union_status, union_activity, hometown_provinces_name, temporary_district_name, permanent_district_name, manager_name, work_location_address, organization_name, job_title_name, nationality_name) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (id, emp_code, emp_code_old, nationality_id, occupation_id, last_name, middle_name, first_name, full_name, gender, religion_id, ethnicity_id, temporary_address, temporary_district_id, permanent_address, permanent_district_id, email_internal, email_external, phone, secondary_phone, home_phone, company_phone, profile_introduced, job_title_id, organization_id, work_location_id, note, old_identity_no, old_date_issue, old_place_issue_id, identity_type, identity_no, date_issue, date_identity_expiry, place_issue_id, date_join, date_probation_start, date_official_start, date_resign, last_work_date, blood_group, blood_pressure, height_cm, weight_kg, job_change_type, manager_id, decision_no, decision_signer, decision_sign_date, start_date_change, end_date_change, work_note, tax_no, cif_code, bank_account_no, bank_name, is_social_insurance, is_unemployment_insurance, is_life_insurance, party_start_date, union_youth_start_date, party_official_date, military_start_date, military_end_date, military_highest_rank, is_old_regime, is_wounded_soldier, en_cert_id, it_cert_id, degree_type, academic, institution, faculty, major, graduation_year, employee_type, hometown_provinces_id, marital_status, education_level, dob, avatar, recruitment, union_start_date, union_fee_date, union_decision_no, union_decision_date, union_appointment_no, union_position, union_organization_name, union_status, union_activity, created_at, created_by, modified_at, modified_by) FROM stdin;
\.


--
-- Data for Name: entity_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.entity_permission (entity_id, entity_type, role_id, id) FROM stdin;
\.


--
-- Data for Name: enum_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enum_category (id, code, name, is_active, sort_order, description, created_at) FROM stdin;
\.


--
-- Data for Name: enum_lookup; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enum_lookup (id, category_id, value, name, is_active, sort_order, description, created_at, created_by, modified_at, modified_by) FROM stdin;
\.


--
-- Data for Name: external_experiences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.external_experiences (id, emp_id, "position", company_name, address, start_date, end_date, start_salary, current_salary, phone, contact, contact_position, main_duty, reason_leave, note) FROM stdin;
\.


--
-- Data for Name: family_dependents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.family_dependents (id, emp_id, full_name, gender, address, phone, email, identity_no, identity_type, tax_no, is_tax_dependent, occupation, workplace, before_1975, after_1975, note, is_alive, relationship_type_id, relative_emp_id, is_dependent, reason, deduction_start_date, deduction_end_date, created_at, created_by, modified_at, modified_by, dob) FROM stdin;
\.


--
-- Data for Name: feature_action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.feature_action (id, feature_id, action_id) FROM stdin;
\.


--
-- Data for Name: features; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.features (id, code, name, description, parent_id, is_active) FROM stdin;
\.


--
-- Data for Name: form_definition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.form_definition (id, code, description, json_schema, name) FROM stdin;
\.


--
-- Data for Name: grid_definition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grid_definition (id, column_def, default_sort, report_code) FROM stdin;
\.


--
-- Data for Name: job_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_assignments (id, emp_id, job_title_id, org_id, cost_center_id, start_date, end_date, is_active, description) FROM stdin;
\.


--
-- Data for Name: job_grades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_grades (id, level, code, name, en_name) FROM stdin;
\.


--
-- Data for Name: job_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_groups (id, code, name, en_name, is_active, sort_order, description) FROM stdin;
\.


--
-- Data for Name: job_title_organizations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_title_organizations (id, job_title_id, org_id, staff_allocation, note, is_active, job_desc, job_position_name) FROM stdin;
\.


--
-- Data for Name: job_titles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_titles (id, code, name, en_name, foreign_name, group_id, is_management, grade_id, parent_id, cost_center_id, is_active, sort_order, description, created_at, created_by, modified_at, modified_by) FROM stdin;
\.


--
-- Data for Name: locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.locations (id, name, districts_id, address, description) FROM stdin;
\.


--
-- Data for Name: national; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."national" (id, code, name, en_name, is_active) FROM stdin;
\.


--
-- Data for Name: org_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.org_log (id, org_id, target_org_id, action, reason, log_date, code, name, en_name, category_id, parent_org_id, location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, approve_struct, decision_no, decision_date, description, version, created_at, created_by, modified_at, modified_by, general_manager_id, direct_manager_id) FROM stdin;
\.


--
-- Data for Name: org_log_attachment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.org_log_attachment (id, log_id, attachment_id) FROM stdin;
\.


--
-- Data for Name: org_log_detail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.org_log_detail (id, org_log_id, target_org_id) FROM stdin;
\.


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.organizations (id, code, name, en_name, category_id, parent_org_id, location_id, phone, email, effective_date, expired_date, cost_centers_id, is_active, decision_no, decision_date, version, description, created_at, modified_at, created_by, modified_by, general_manager_id, direct_manager_id, approve_struct) FROM stdin;
\.


--
-- Data for Name: passports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.passports (id, emp_id, passport_no, type, date_issue, expired_date, place_issue) FROM stdin;
\.


--
-- Data for Name: project_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_members (id, project_id, emp_id, role, main_tasks, join_date, exit_date, note) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, code, name, en_name, start_date, end_date, status, description, note) FROM stdin;
\.


--
-- Data for Name: provinces; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provinces (id, code, name, en_name, rank, note, is_active, description) FROM stdin;
\.


--
-- Data for Name: relationship_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.relationship_types (id, code, en_name, name) FROM stdin;
\.


--
-- Data for Name: report_audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_audit_log (id, duration_ms, error_message, executed_at, filter_params, report_code, result_summary, success, tenant_id, user_id) FROM stdin;
\.


--
-- Data for Name: report_definition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_definition (id, code, filter_form_code, is_active, name, output_file_prefix, sp_name, template_file_path, parent_id, group_name) FROM stdin;
\.


--
-- Data for Name: report_export_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_export_log (id, duration_ms, exported_at, file_path, params_json, record_count, report_code, tenant_id, user_id) FROM stdin;
\.


--
-- Data for Name: report_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_group (id, group_name, module) FROM stdin;
\.


--
-- Data for Name: result; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.result (jsonb_build_object) FROM stdin;
\.


--
-- Data for Name: reward_disciplinary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reward_disciplinary (id, emp_id, decision_no, type_reward_id, issuer, issuer_position, decision_date, start_date, end_date, note, type, form, reason, decision_authority_name, achievement) FROM stdin;
\.


--
-- Data for Name: reward_disciplinary_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reward_disciplinary_types (id, type, category, exemplary_level, reason, description) FROM stdin;
\.


--
-- Data for Name: role_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permission (id, role_id, feature_id, action_id, scope) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, code, name, description, is_active) FROM stdin;
\.


--
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_role (user_id, role_id) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, preferred_username, email) FROM stdin;
\.


--
-- Data for Name: v_degree_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.v_degree_info (id, emp_id, is_main, type, degree_no, academic, institution, classification, faculty, major, education_mode, start_date, end_date, graduation_year, training_location, note) FROM stdin;
\.


--
-- Data for Name: work_histories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_histories (id, emp_id, job_title_id, organization_id, change_type_id, decision_no, decision_signer, decision_sign_date, start_date, end_date, reason, note, work_place, organization_name, job_title_name) FROM stdin;
\.


--
-- Name: abroad_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.abroad_records_id_seq', 1, false);


--
-- Name: actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.actions_id_seq', 20, false);


--
-- Name: attachment_files_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attachment_files_view_id_seq', 1, false);


--
-- Name: attachment_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attachment_link_id_seq', 1, false);


--
-- Name: attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attachments_id_seq', 1, false);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1, false);


--
-- Name: certificates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.certificates_id_seq', 4102, false);


--
-- Name: cost_centers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cost_centers_id_seq', 1306, false);


--
-- Name: degrees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.degrees_id_seq', 1, false);


--
-- Name: districts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.districts_id_seq', 2494, false);


--
-- Name: emp_draft_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.emp_draft_id_seq', 1, false);


--
-- Name: employee_detail_profile_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_detail_profile_view_id_seq', 9222, false);


--
-- Name: employee_health_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_health_id_seq', 1, false);


--
-- Name: employee_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_histories_id_seq', 178089, false);


--
-- Name: employee_list_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_list_view_id_seq', 9222, false);


--
-- Name: employees_export_full_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_export_full_view_id_seq', 9222, false);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_id_seq', 1, false);


--
-- Name: entity_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.entity_permission_id_seq', 1, false);


--
-- Name: enum_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enum_category_id_seq', 21, false);


--
-- Name: enum_lookup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enum_lookup_id_seq', 1759, false);


--
-- Name: external_experiences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.external_experiences_id_seq', 16664, false);


--
-- Name: family_dependents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.family_dependents_id_seq', 40836, false);


--
-- Name: feature_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.feature_action_id_seq', 138, false);


--
-- Name: feature_action_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.feature_action_view_id_seq', 138, false);


--
-- Name: features_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.features_id_seq', 63, false);


--
-- Name: job_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_assignments_id_seq', 1, false);


--
-- Name: job_grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_grades_id_seq', 1, false);


--
-- Name: job_grades_unique_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_grades_unique_view_id_seq', 1, false);


--
-- Name: job_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_groups_id_seq', 4, false);


--
-- Name: job_title_detail_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_title_detail_view_id_seq', 1564, false);


--
-- Name: job_title_organizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_title_organizations_id_seq', 11062, false);


--
-- Name: job_titles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_titles_id_seq', 1564, false);


--
-- Name: list_emp_by_job_title_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.list_emp_by_job_title_view_id_seq', 9222, false);


--
-- Name: locations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.locations_id_seq', 1122, false);


--
-- Name: national_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.national_id_seq', 107, false);


--
-- Name: org_log_attachment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.org_log_attachment_id_seq', 1, false);


--
-- Name: org_log_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.org_log_detail_id_seq', 3, false);


--
-- Name: org_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.org_log_id_seq', 2117, false);


--
-- Name: organization_details_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.organization_details_view_id_seq', 2110, false);


--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.organizations_id_seq', 2110, false);


--
-- Name: passports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.passports_id_seq', 1, false);


--
-- Name: positions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.positions_id_seq', 11062, false);


--
-- Name: project_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_members_id_seq', 1, false);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_id_seq', 1, false);


--
-- Name: provinces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.provinces_id_seq', 378, false);


--
-- Name: relationship_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.relationship_types_id_seq', 264, false);


--
-- Name: reward_disciplinary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reward_disciplinary_id_seq', 30946, false);


--
-- Name: reward_disciplinary_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reward_disciplinary_types_id_seq', 1, false);


--
-- Name: reward_disciplinary_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reward_disciplinary_view_id_seq', 30946, false);


--
-- Name: role_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_permission_id_seq', 428, false);


--
-- Name: role_permission_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_permission_view_id_seq', 428, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 13, false);


--
-- Name: v_degree_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.v_degree_info_id_seq', 1, false);


--
-- Name: vw_export_employees_full_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vw_export_employees_full_id_seq', 9222, false);


--
-- Name: work_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.work_histories_id_seq', 45917, false);


--
-- Name: abroad_records abroad_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.abroad_records
    ADD CONSTRAINT abroad_records_pkey PRIMARY KEY (id);


--
-- Name: abroad_records abroad_records_visas_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.abroad_records
    ADD CONSTRAINT abroad_records_visas_no_key UNIQUE (visas_no);


--
-- Name: actions actions_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_code_key UNIQUE (code);


--
-- Name: actions actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_pkey PRIMARY KEY (id);


--
-- Name: attachment_link attachment_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachment_link
    ADD CONSTRAINT attachment_link_pkey PRIMARY KEY (id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: certificates certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_pkey PRIMARY KEY (id);


--
-- Name: cost_centers cost_centers_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT cost_centers_code_key UNIQUE (code);


--
-- Name: cost_centers cost_centers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cost_centers
    ADD CONSTRAINT cost_centers_pkey PRIMARY KEY (id);


--
-- Name: degrees degrees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degrees
    ADD CONSTRAINT degrees_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: employee_health employee_health_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_health
    ADD CONSTRAINT employee_health_pkey PRIMARY KEY (id);


--
-- Name: employee_histories employee_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_histories
    ADD CONSTRAINT employee_histories_pkey PRIMARY KEY (id);


--
-- Name: employees employees_emp_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_emp_code_key UNIQUE (emp_code);


--
-- Name: employees employees_emp_code_old_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_emp_code_old_key UNIQUE (emp_code_old);


--
-- Name: employees employees_identity_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_identity_no_key UNIQUE (identity_no);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: entity_permission entity_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entity_permission
    ADD CONSTRAINT entity_permission_pkey PRIMARY KEY (id, role_id);


--
-- Name: enum_category enum_category_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enum_category
    ADD CONSTRAINT enum_category_code_key UNIQUE (code);


--
-- Name: enum_category enum_category_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enum_category
    ADD CONSTRAINT enum_category_name_key UNIQUE (name);


--
-- Name: enum_category enum_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enum_category
    ADD CONSTRAINT enum_category_pkey PRIMARY KEY (id);


--
-- Name: enum_lookup enum_lookup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enum_lookup
    ADD CONSTRAINT enum_lookup_pkey PRIMARY KEY (id);


--
-- Name: enum_lookup enum_lookup_value_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enum_lookup
    ADD CONSTRAINT enum_lookup_value_key UNIQUE (value);


--
-- Name: external_experiences external_experiences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.external_experiences
    ADD CONSTRAINT external_experiences_pkey PRIMARY KEY (id);


--
-- Name: family_dependents family_dependents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_dependents
    ADD CONSTRAINT family_dependents_pkey PRIMARY KEY (id);


--
-- Name: feature_action feature_action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feature_action
    ADD CONSTRAINT feature_action_pkey PRIMARY KEY (id);


--
-- Name: features features_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.features
    ADD CONSTRAINT features_code_key UNIQUE (code);


--
-- Name: features features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);


--
-- Name: form_definition form_definition_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_definition
    ADD CONSTRAINT form_definition_code_key UNIQUE (code);


--
-- Name: form_definition form_definition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_definition
    ADD CONSTRAINT form_definition_pkey PRIMARY KEY (id);


--
-- Name: grid_definition grid_definition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grid_definition
    ADD CONSTRAINT grid_definition_pkey PRIMARY KEY (id);


--
-- Name: job_assignments job_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_assignments
    ADD CONSTRAINT job_assignments_pkey PRIMARY KEY (id);


--
-- Name: job_grades job_grades_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_grades
    ADD CONSTRAINT job_grades_code_key UNIQUE (code);


--
-- Name: job_grades job_grades_level_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_grades
    ADD CONSTRAINT job_grades_level_name_key UNIQUE (level, name);


--
-- Name: job_grades job_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_grades
    ADD CONSTRAINT job_grades_pkey PRIMARY KEY (id);


--
-- Name: job_groups job_groups_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_groups
    ADD CONSTRAINT job_groups_code_key UNIQUE (code);


--
-- Name: job_groups job_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_groups
    ADD CONSTRAINT job_groups_pkey PRIMARY KEY (id);


--
-- Name: job_title_organizations job_title_organizations_job_title_id_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_title_organizations
    ADD CONSTRAINT job_title_organizations_job_title_id_org_id_key UNIQUE (job_title_id, org_id);


--
-- Name: job_title_organizations job_title_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_title_organizations
    ADD CONSTRAINT job_title_organizations_pkey PRIMARY KEY (id);


--
-- Name: job_titles job_titles_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_titles
    ADD CONSTRAINT job_titles_code_key UNIQUE (code);


--
-- Name: job_titles job_titles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_titles
    ADD CONSTRAINT job_titles_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: national national_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."national"
    ADD CONSTRAINT national_pkey PRIMARY KEY (id);


--
-- Name: org_log_attachment org_log_attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log_attachment
    ADD CONSTRAINT org_log_attachment_pkey PRIMARY KEY (id);


--
-- Name: org_log_detail org_log_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log_detail
    ADD CONSTRAINT org_log_detail_pkey PRIMARY KEY (id);


--
-- Name: org_log org_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log
    ADD CONSTRAINT org_log_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_code_key UNIQUE (code);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: passports passports_emp_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passports
    ADD CONSTRAINT passports_emp_id_key UNIQUE (emp_id);


--
-- Name: passports passports_passport_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passports
    ADD CONSTRAINT passports_passport_no_key UNIQUE (passport_no);


--
-- Name: passports passports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passports
    ADD CONSTRAINT passports_pkey PRIMARY KEY (id);


--
-- Name: project_members project_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_pkey PRIMARY KEY (id);


--
-- Name: projects projects_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_code_key UNIQUE (code);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: provinces provinces_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_code_key UNIQUE (code);


--
-- Name: provinces provinces_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_pkey PRIMARY KEY (id);


--
-- Name: relationship_types relationship_types_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationship_types
    ADD CONSTRAINT relationship_types_code_key UNIQUE (code);


--
-- Name: relationship_types relationship_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relationship_types
    ADD CONSTRAINT relationship_types_pkey PRIMARY KEY (id);


--
-- Name: report_audit_log report_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_audit_log
    ADD CONSTRAINT report_audit_log_pkey PRIMARY KEY (id);


--
-- Name: report_definition report_definition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_definition
    ADD CONSTRAINT report_definition_pkey PRIMARY KEY (id);


--
-- Name: report_export_log report_export_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_export_log
    ADD CONSTRAINT report_export_log_pkey PRIMARY KEY (id);


--
-- Name: report_group report_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_group
    ADD CONSTRAINT report_group_pkey PRIMARY KEY (id);


--
-- Name: reward_disciplinary reward_disciplinary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_disciplinary
    ADD CONSTRAINT reward_disciplinary_pkey PRIMARY KEY (id);


--
-- Name: reward_disciplinary_types reward_disciplinary_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_disciplinary_types
    ADD CONSTRAINT reward_disciplinary_types_pkey PRIMARY KEY (id);


--
-- Name: role_permission role_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_pkey PRIMARY KEY (id);


--
-- Name: roles roles_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_code_key UNIQUE (code);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: report_definition uk_j7gh9qltrbxjtfj5b601m4it4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_definition
    ADD CONSTRAINT uk_j7gh9qltrbxjtfj5b601m4it4 UNIQUE (code);


--
-- Name: report_group unique_module_group_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_group
    ADD CONSTRAINT unique_module_group_name UNIQUE (module, group_name);


--
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: work_histories work_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_histories
    ADD CONSTRAINT work_histories_pkey PRIMARY KEY (id);


--
-- Name: employees_emp_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX employees_emp_code_idx ON public.employees USING btree (emp_code);


--
-- Name: employees_full_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX employees_full_name_idx ON public.employees USING btree (full_name);


--
-- Name: employees_job_title_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX employees_job_title_id_idx ON public.employees USING btree (job_title_id);


--
-- Name: employees_organization_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX employees_organization_id_idx ON public.employees USING btree (organization_id);


--
-- Name: idx_employees_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_created_at ON public.employees USING btree (created_at);


--
-- Name: organizations_parent_org_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX organizations_parent_org_id_idx ON public.organizations USING btree (parent_org_id);


--
-- Name: attachments audit_attachments; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_attachments BEFORE INSERT OR UPDATE ON public.attachments FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();


--
-- Name: employee_histories audit_employee_histories; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_employee_histories BEFORE INSERT OR UPDATE ON public.employee_histories FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();


--
-- Name: enum_lookup audit_enum_lookup; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_enum_lookup BEFORE INSERT OR UPDATE ON public.enum_lookup FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();


--
-- Name: organizations audit_organizations; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_organizations BEFORE INSERT OR UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();


--
-- Name: org_log audit_organizations_log; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_organizations_log BEFORE INSERT OR UPDATE ON public.org_log FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();


--
-- Name: job_titles job_titles_audit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER job_titles_audit_trigger BEFORE INSERT OR UPDATE ON public.job_titles FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();


--
-- Name: certificates trg_audit_certificates; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_certificates AFTER INSERT OR DELETE OR UPDATE ON public.certificates FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: degrees trg_audit_degrees; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_degrees AFTER INSERT OR DELETE OR UPDATE ON public.degrees FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: employees trg_audit_employees; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_employees AFTER INSERT OR DELETE OR UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: enum_lookup trg_audit_enum_lookup; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_enum_lookup AFTER INSERT OR DELETE OR UPDATE ON public.enum_lookup FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: family_dependents trg_audit_family_dependents; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_family_dependents AFTER INSERT OR DELETE OR UPDATE ON public.family_dependents FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: job_title_organizations trg_audit_job_title_organizations; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_job_title_organizations AFTER INSERT OR DELETE OR UPDATE ON public.job_title_organizations FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: job_titles trg_audit_job_titles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_job_titles AFTER INSERT OR DELETE OR UPDATE ON public.job_titles FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: organizations trg_audit_organizations; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_organizations AFTER INSERT OR DELETE OR UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: report_group trg_audit_report_group; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_report_group AFTER INSERT OR DELETE OR UPDATE ON public.report_group FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: reward_disciplinary trg_audit_reward_disciplinary; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_reward_disciplinary AFTER INSERT OR DELETE OR UPDATE ON public.reward_disciplinary FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: role_permission trg_audit_role_permissions; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_role_permissions AFTER INSERT OR DELETE OR UPDATE ON public.role_permission FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: roles trg_audit_roles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_roles AFTER INSERT OR DELETE OR UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: user_role trg_audit_user_role; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_user_role AFTER INSERT OR DELETE OR UPDATE ON public.user_role FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: users trg_audit_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_users AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_generic();


--
-- Name: attachment_link attachment_link_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachment_link
    ADD CONSTRAINT attachment_link_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.attachments(id) ON DELETE CASCADE;


--
-- Name: certificates certificates_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: certificates certificates_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.enum_lookup(id);


--
-- Name: districts districts_province_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id);


--
-- Name: employee_health employee_health_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_health
    ADD CONSTRAINT employee_health_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: employees employees_en_cert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_en_cert_id_fkey FOREIGN KEY (en_cert_id) REFERENCES public.enum_lookup(id);


--
-- Name: employees employees_ethnicity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_ethnicity_id_fkey FOREIGN KEY (ethnicity_id) REFERENCES public.enum_lookup(id);


--
-- Name: employees employees_hometown_provinces_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_hometown_provinces_id_fkey FOREIGN KEY (hometown_provinces_id) REFERENCES public.provinces(id);


--
-- Name: employees employees_it_cert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_it_cert_id_fkey FOREIGN KEY (it_cert_id) REFERENCES public.enum_lookup(id);


--
-- Name: employees employees_job_title_organization_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_job_title_organization_fkey FOREIGN KEY (job_title_id, organization_id) REFERENCES public.job_title_organizations(job_title_id, org_id);


--
-- Name: employees employees_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.employees(id);


--
-- Name: employees employees_occupation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_occupation_id_fkey FOREIGN KEY (occupation_id) REFERENCES public.enum_lookup(id);


--
-- Name: employees employees_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: employees employees_permanent_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_permanent_district_id_fkey FOREIGN KEY (permanent_district_id) REFERENCES public.districts(id);


--
-- Name: employees employees_place_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_place_issue_id_fkey FOREIGN KEY (place_issue_id) REFERENCES public.enum_lookup(id);


--
-- Name: employees employees_religion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_religion_id_fkey FOREIGN KEY (religion_id) REFERENCES public.enum_lookup(id);


--
-- Name: employees employees_temporary_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_temporary_district_id_fkey FOREIGN KEY (temporary_district_id) REFERENCES public.districts(id);


--
-- Name: employees employees_work_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_work_location_id_fkey FOREIGN KEY (work_location_id) REFERENCES public.locations(id);


--
-- Name: entity_permission entity_permission_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entity_permission
    ADD CONSTRAINT entity_permission_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: enum_lookup enum_lookup_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enum_lookup
    ADD CONSTRAINT enum_lookup_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.enum_category(id);


--
-- Name: family_dependents family_dependents_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_dependents
    ADD CONSTRAINT family_dependents_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: family_dependents family_dependents_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_dependents
    ADD CONSTRAINT family_dependents_relationship_type_id_fkey FOREIGN KEY (relationship_type_id) REFERENCES public.relationship_types(id);


--
-- Name: family_dependents family_dependents_relative_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_dependents
    ADD CONSTRAINT family_dependents_relative_emp_id_fkey FOREIGN KEY (relative_emp_id) REFERENCES public.employees(id);


--
-- Name: feature_action feature_action_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feature_action
    ADD CONSTRAINT feature_action_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.actions(id) ON DELETE CASCADE;


--
-- Name: feature_action feature_action_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feature_action
    ADD CONSTRAINT feature_action_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.features(id) ON DELETE CASCADE;


--
-- Name: features features_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.features
    ADD CONSTRAINT features_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.features(id) ON DELETE SET NULL;


--
-- Name: report_audit_log fk3o4d6vahivpajjr3tr70vk7tg; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_audit_log
    ADD CONSTRAINT fk3o4d6vahivpajjr3tr70vk7tg FOREIGN KEY (report_code) REFERENCES public.report_definition(code);


--
-- Name: abroad_records fk_abroad_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.abroad_records
    ADD CONSTRAINT fk_abroad_emp FOREIGN KEY (emp_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: abroad_records fk_abroad_national; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.abroad_records
    ADD CONSTRAINT fk_abroad_national FOREIGN KEY (national_id) REFERENCES public."national"(id) ON DELETE SET NULL;


--
-- Name: job_titles fk_cost_center; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_titles
    ADD CONSTRAINT fk_cost_center FOREIGN KEY (cost_center_id) REFERENCES public.cost_centers(id);


--
-- Name: degrees fk_degree_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degrees
    ADD CONSTRAINT fk_degree_emp FOREIGN KEY (emp_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: external_experiences fk_emp_external_exp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.external_experiences
    ADD CONSTRAINT fk_emp_external_exp FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: job_titles fk_job_grade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_titles
    ADD CONSTRAINT fk_job_grade FOREIGN KEY (grade_id) REFERENCES public.job_grades(id);


--
-- Name: job_titles fk_job_group; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_titles
    ADD CONSTRAINT fk_job_group FOREIGN KEY (group_id) REFERENCES public.job_groups(id);


--
-- Name: employees fk_job_title; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_job_title FOREIGN KEY (job_title_id) REFERENCES public.job_titles(id);


--
-- Name: employee_histories fk_log_emp_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_histories
    ADD CONSTRAINT fk_log_emp_id FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: employees fk_nationality; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_nationality FOREIGN KEY (nationality_id) REFERENCES public."national"(id);


--
-- Name: org_log fk_org_log_cost; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log
    ADD CONSTRAINT fk_org_log_cost FOREIGN KEY (cost_centers_id) REFERENCES public.cost_centers(id) ON DELETE SET NULL;


--
-- Name: org_log_detail fk_org_log_detail_log; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log_detail
    ADD CONSTRAINT fk_org_log_detail_log FOREIGN KEY (org_log_id) REFERENCES public.org_log(id) ON DELETE CASCADE;


--
-- Name: org_log fk_org_log_location; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log
    ADD CONSTRAINT fk_org_log_location FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE SET NULL;


--
-- Name: job_titles fk_parent_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_titles
    ADD CONSTRAINT fk_parent_job FOREIGN KEY (parent_id) REFERENCES public.job_titles(id);


--
-- Name: passports fk_passport_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passports
    ADD CONSTRAINT fk_passport_emp FOREIGN KEY (emp_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: report_export_log fko6c0vgjouim2ctshisxgfmcht; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_export_log
    ADD CONSTRAINT fko6c0vgjouim2ctshisxgfmcht FOREIGN KEY (report_code) REFERENCES public.report_definition(code);


--
-- Name: grid_definition grid_definition_report_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grid_definition
    ADD CONSTRAINT grid_definition_report_code_fkey FOREIGN KEY (report_code) REFERENCES public.report_definition(code);


--
-- Name: job_assignments job_assignments_cost_center_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_assignments
    ADD CONSTRAINT job_assignments_cost_center_id_fkey FOREIGN KEY (cost_center_id) REFERENCES public.cost_centers(id);


--
-- Name: job_assignments job_assignments_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_assignments
    ADD CONSTRAINT job_assignments_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: job_assignments job_assignments_job_title_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_assignments
    ADD CONSTRAINT job_assignments_job_title_id_fkey FOREIGN KEY (job_title_id) REFERENCES public.job_titles(id);


--
-- Name: job_assignments job_assignments_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_assignments
    ADD CONSTRAINT job_assignments_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);


--
-- Name: job_title_organizations job_title_organizations_job_title_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_title_organizations
    ADD CONSTRAINT job_title_organizations_job_title_id_fkey FOREIGN KEY (job_title_id) REFERENCES public.job_titles(id);


--
-- Name: job_title_organizations job_title_organizations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_title_organizations
    ADD CONSTRAINT job_title_organizations_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);


--
-- Name: locations locations_districts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_districts_id_fkey FOREIGN KEY (districts_id) REFERENCES public.districts(id);


--
-- Name: org_log_attachment org_log_attachment_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log_attachment
    ADD CONSTRAINT org_log_attachment_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: org_log_attachment org_log_attachment_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log_attachment
    ADD CONSTRAINT org_log_attachment_log_id_fkey FOREIGN KEY (log_id) REFERENCES public.org_log(id);


--
-- Name: org_log_detail org_log_detail_target_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log_detail
    ADD CONSTRAINT org_log_detail_target_org_id_fkey FOREIGN KEY (target_org_id) REFERENCES public.organizations(id);


--
-- Name: org_log org_log_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log
    ADD CONSTRAINT org_log_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);


--
-- Name: org_log org_log_target_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_log
    ADD CONSTRAINT org_log_target_org_id_fkey FOREIGN KEY (target_org_id) REFERENCES public.organizations(id);


--
-- Name: organizations organizations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.enum_lookup(id);


--
-- Name: organizations organizations_cost_centers_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_cost_centers_id_fkey FOREIGN KEY (cost_centers_id) REFERENCES public.cost_centers(id);


--
-- Name: organizations organizations_direct_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_direct_manager_id_fkey FOREIGN KEY (direct_manager_id) REFERENCES public.employees(id);


--
-- Name: organizations organizations_general_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_general_manager_id_fkey FOREIGN KEY (general_manager_id) REFERENCES public.employees(id);


--
-- Name: organizations organizations_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: organizations organizations_parent_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_parent_org_id_fkey FOREIGN KEY (parent_org_id) REFERENCES public.organizations(id);


--
-- Name: project_members project_members_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: project_members project_members_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: report_definition report_definition_filter_form_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_definition
    ADD CONSTRAINT report_definition_filter_form_code_fkey FOREIGN KEY (filter_form_code) REFERENCES public.form_definition(code);


--
-- Name: report_definition report_definition_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_definition
    ADD CONSTRAINT report_definition_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.report_group(id);


--
-- Name: reward_disciplinary reward_disciplinary_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_disciplinary
    ADD CONSTRAINT reward_disciplinary_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: reward_disciplinary reward_disciplinary_form_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_disciplinary
    ADD CONSTRAINT reward_disciplinary_form_fkey FOREIGN KEY (form) REFERENCES public.enum_lookup(id);


--
-- Name: reward_disciplinary reward_disciplinary_type_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_disciplinary
    ADD CONSTRAINT reward_disciplinary_type_reward_id_fkey FOREIGN KEY (type_reward_id) REFERENCES public.enum_lookup(id);


--
-- Name: role_permission role_permission_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.actions(id) ON DELETE CASCADE;


--
-- Name: role_permission role_permission_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.features(id) ON DELETE CASCADE;


--
-- Name: role_permission role_permission_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_role user_role_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: user_role user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: work_histories work_histories_change_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_histories
    ADD CONSTRAINT work_histories_change_type_id_fkey FOREIGN KEY (change_type_id) REFERENCES public.enum_lookup(id);


--
-- Name: work_histories work_histories_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_histories
    ADD CONSTRAINT work_histories_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(id);


--
-- Name: work_histories work_histories_job_title_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_histories
    ADD CONSTRAINT work_histories_job_title_id_fkey FOREIGN KEY (job_title_id) REFERENCES public.job_titles(id);


--
-- Name: work_histories work_histories_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_histories
    ADD CONSTRAINT work_histories_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: feature_action; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.feature_action ENABLE ROW LEVEL SECURITY;

--
-- Name: features; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.features ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

