-- Migration gerada para replicar funcoes no schema public

CREATE OR REPLACE FUNCTION public.atualizar_curva_abcd(p_schema_name text, p_filiais_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    dyn_sql text;
    start_time timestamptz := clock_timestamp();
    filial_filter_clause text := '';
BEGIN
    IF p_filiais_ids IS NOT NULL AND array_length(p_filiais_ids, 1) > 0 THEN
        filial_filter_clause := format('AND p.filial_id = ANY(%L)', p_filiais_ids);
    END IF;

    dyn_sql := format($f$
        CREATE TEMP TABLE temp_curva_final (
            id_produto bigint,
            filial_id bigint,
            curva_final text
        ) ON COMMIT DROP;

        WITH
        calculo_base AS (
            SELECT
                p.filial_id,
                p.departamento_id,
                p.id as id_produto,
                COALESCE(SUM(v.valor_vendas), 0) as total_valor_produto,
                SUM(COALESCE(SUM(v.valor_vendas), 0)) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_departamento,
                ROW_NUMBER() OVER (PARTITION BY p.filial_id, p.departamento_id ORDER BY COALESCE(SUM(v.valor_vendas), 0) DESC) as ranking,
                COUNT(*) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_produtos_no_grupo
            FROM
                %1$I.produtos p
            LEFT JOIN
                %1$I.vendas v ON p.id = v.id_produto
                                AND p.filial_id = v.filial_id
                                AND v.data_venda >= (CURRENT_DATE - INTERVAL '60 days')
                                AND v.data_venda < CURRENT_DATE
                                AND v.valor_vendas > 0
            WHERE
                p.ativo = true
                %2$s
            GROUP BY
                p.filial_id, p.departamento_id, p.id
        ),
        calculo_curva_inicial AS (
            SELECT
                *,
                SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as acumulado,
                CASE
                    WHEN total_valor_produto = 0 THEN 'SV'
                    WHEN (total_valor_produto / NULLIF(total_departamento, 0)) > 0.50 THEN 'A'
                    WHEN (SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_departamento, 0)) <= 0.51 THEN 'A'
                    WHEN (SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_departamento, 0)) <= 0.81 THEN 'B'
                    WHEN (SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_departamento, 0)) <= 0.91 THEN 'C'
                    ELSE 'D'
                END AS curva_inicial
            FROM
                calculo_base
        ),
        analise_de_presenca AS (
            SELECT
                *,
                BOOL_OR(curva_inicial = 'A') OVER (PARTITION BY filial_id, departamento_id) as tem_A,
                BOOL_OR(curva_inicial = 'B') OVER (PARTITION BY filial_id, departamento_id) as tem_B,
                BOOL_OR(curva_inicial = 'C') OVER (PARTITION BY filial_id, departamento_id) as tem_C
            FROM
                calculo_curva_inicial
        )
        INSERT INTO temp_curva_final (id_produto, filial_id, curva_final)
        SELECT
            id_produto,
            filial_id,
            CASE
                WHEN curva_inicial = 'SV' THEN 'SV'
                WHEN total_produtos_no_grupo = 1 THEN 'A'
                WHEN tem_A = false AND ranking = 1 THEN 'A'
                WHEN tem_B = false AND ranking = 2 AND total_produtos_no_grupo >= 2 THEN 'B'
                WHEN tem_C = false AND ranking = 3 AND total_produtos_no_grupo >= 3 THEN 'C'
                ELSE curva_inicial
            END AS curva_final
        FROM
            analise_de_presenca;

        UPDATE %1$I.produtos p
        SET curva_abcd = tcf.curva_final
        FROM temp_curva_final tcf
        WHERE p.id = tcf.id_produto AND p.filial_id = tcf.filial_id;

    $f$, p_schema_name, filial_filter_clause);

    EXECUTE dyn_sql;

    PERFORM public.log_job('atualizar_curva_abcd', p_schema_name, 'SUCCESS', 'Filiais: ' || COALESCE(p_filiais_ids::text, 'TODAS'), start_time);

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job('atualizar_curva_abcd', p_schema_name, 'ERROR', SQLERRM, start_time);
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_curva_abcd_30d(p_schema_name text, p_filiais_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    dyn_sql text;
    start_time timestamptz := clock_timestamp();
    filial_filter_clause text := '';
BEGIN
    IF p_filiais_ids IS NOT NULL AND array_length(p_filiais_ids, 1) > 0 THEN
        filial_filter_clause := format('AND p.filial_id = ANY(%L)', p_filiais_ids);
    END IF;

    dyn_sql := format($f$
        CREATE TEMP TABLE temp_curva_final (
            id_produto bigint,
            filial_id bigint,
            curva_final text
        ) ON COMMIT DROP;

        WITH
        calculo_base AS (
            SELECT
                p.filial_id,
                p.departamento_id,
                p.id as id_produto,
                COALESCE(SUM(v.valor_vendas), 0) as total_valor_produto,
                SUM(COALESCE(SUM(v.valor_vendas), 0)) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_departamento,
                ROW_NUMBER() OVER (PARTITION BY p.filial_id, p.departamento_id ORDER BY COALESCE(SUM(v.valor_vendas), 0) DESC) as ranking,
                COUNT(*) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_produtos_no_grupo
            FROM
                %1$I.produtos p
            LEFT JOIN
                %1$I.vendas v ON p.id = v.id_produto
                                AND p.filial_id = v.filial_id
                                AND v.data_venda >= (CURRENT_DATE - INTERVAL '30 days')
                                AND v.data_venda < CURRENT_DATE
                                AND v.valor_vendas > 0
            WHERE
                p.ativo = true
                %2$s
            GROUP BY
                p.filial_id, p.departamento_id, p.id
        ),
        calculo_curva_inicial AS (
            SELECT
                *,
                SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as acumulado,
                CASE
                    WHEN total_valor_produto = 0 THEN 'SV'
                    WHEN (total_valor_produto / NULLIF(total_departamento, 0)) > 0.50 THEN 'A'
                    WHEN (SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_departamento, 0)) <= 0.51 THEN 'A'
                    WHEN (SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_departamento, 0)) <= 0.81 THEN 'B'
                    WHEN (SUM(total_valor_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_departamento, 0)) <= 0.91 THEN 'C'
                    ELSE 'D'
                END AS curva_inicial
            FROM
                calculo_base
        ),
        analise_de_presenca AS (
            SELECT
                *,
                BOOL_OR(curva_inicial = 'A') OVER (PARTITION BY filial_id, departamento_id) as tem_A,
                BOOL_OR(curva_inicial = 'B') OVER (PARTITION BY filial_id, departamento_id) as tem_B,
                BOOL_OR(curva_inicial = 'C') OVER (PARTITION BY filial_id, departamento_id) as tem_C
            FROM
                calculo_curva_inicial
        )
        INSERT INTO temp_curva_final (id_produto, filial_id, curva_final)
        SELECT
            id_produto,
            filial_id,
            CASE
                WHEN curva_inicial = 'SV' THEN 'SV'
                WHEN total_produtos_no_grupo = 1 THEN 'A'
                WHEN tem_A = false AND ranking = 1 THEN 'A'
                WHEN tem_B = false AND ranking = 2 AND total_produtos_no_grupo >= 2 THEN 'B'
                WHEN tem_C = false AND ranking = 3 AND total_produtos_no_grupo >= 3 THEN 'C'
                ELSE curva_inicial
            END AS curva_final
        FROM
            analise_de_presenca;

        UPDATE %1$I.produtos p
        SET curva_abcd = tcf.curva_final
        FROM temp_curva_final tcf
        WHERE p.id = tcf.id_produto AND p.filial_id = tcf.filial_id;

    $f$, p_schema_name, filial_filter_clause);

    EXECUTE dyn_sql;

    PERFORM public.log_job('atualizar_curva_abcd_30d', p_schema_name, 'SUCCESS', 'Filiais: ' || COALESCE(p_filiais_ids::text, 'TODAS'), start_time);

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job('atualizar_curva_abcd_30d', p_schema_name, 'ERROR', SQLERRM, start_time);
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_curva_lucro(p_schema_name text, p_filiais_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    dyn_sql text;
    start_time timestamptz := clock_timestamp();
    filial_filter_clause text := '';
BEGIN
    IF p_filiais_ids IS NOT NULL AND array_length(p_filiais_ids, 1) > 0 THEN
        filial_filter_clause := format('AND p.filial_id = ANY(%L)', p_filiais_ids);
    END IF;

    dyn_sql := format($f$
        CREATE TEMP TABLE temp_curva_lucro_final (
            id_produto bigint,
            filial_id bigint,
            curva_final varchar(2)
        ) ON COMMIT DROP;

        WITH
        calculo_base AS (
            SELECT
                p.filial_id,
                p.departamento_id,
                p.id as id_produto,
                COALESCE(SUM(v.valor_vendas - (v.quantidade * p.custo_medio)), 0) as total_lucro_produto,
                SUM(COALESCE(SUM(v.valor_vendas - (v.quantidade * p.custo_medio)), 0)) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_lucro_departamento,
                ROW_NUMBER() OVER (PARTITION BY p.filial_id, p.departamento_id ORDER BY COALESCE(SUM(v.valor_vendas - (v.quantidade * p.custo_medio)), 0) DESC) as ranking,
                COUNT(*) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_produtos_no_grupo
            FROM
                %1$I.produtos p
            LEFT JOIN
                %1$I.vendas v ON p.id = v.id_produto
                                AND p.filial_id = v.filial_id
                                AND v.data_venda >= (CURRENT_DATE - INTERVAL '30 days')
                                AND v.data_venda < CURRENT_DATE
            WHERE
                p.ativo = true
                %2$s
            GROUP BY
                p.filial_id, p.departamento_id, p.id
        ),
        calculo_curva_inicial AS (
            SELECT
                *,
                SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as acumulado,
                CASE
                    WHEN total_lucro_produto <= 0 THEN 'SL'
                    WHEN (total_lucro_produto / NULLIF(total_lucro_departamento, 0)) > 0.50 THEN 'A'
                    WHEN (SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_lucro_departamento, 0)) <= 0.51 THEN 'A'
                    WHEN (SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_lucro_departamento, 0)) <= 0.81 THEN 'B'
                    WHEN (SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_lucro_departamento, 0)) <= 0.91 THEN 'C'
                    ELSE 'D'
                END AS curva_inicial
            FROM
                calculo_base
        ),
        analise_de_presenca AS (
            SELECT
                *,
                BOOL_OR(curva_inicial = 'A') OVER (PARTITION BY filial_id, departamento_id) as tem_A,
                BOOL_OR(curva_inicial = 'B') OVER (PARTITION BY filial_id, departamento_id) as tem_B,
                BOOL_OR(curva_inicial = 'C') OVER (PARTITION BY filial_id, departamento_id) as tem_C
            FROM
                calculo_curva_inicial
        )
        INSERT INTO temp_curva_lucro_final (id_produto, filial_id, curva_final)
        SELECT
            id_produto,
            filial_id,
            CASE
                WHEN curva_inicial = 'SL' THEN 'SL'
                WHEN total_produtos_no_grupo = 1 THEN 'A'
                WHEN tem_A = false AND ranking = 1 THEN 'A'
                WHEN tem_B = false AND ranking = 2 AND total_produtos_no_grupo >= 2 THEN 'B'
                WHEN tem_C = false AND ranking = 3 AND total_produtos_no_grupo >= 3 THEN 'C'
                ELSE curva_inicial
            END AS curva_final
        FROM
            analise_de_presenca;

        UPDATE %1$I.produtos p
        SET curva_lucro = tcf.curva_final
        FROM temp_curva_lucro_final tcf
        WHERE p.id = tcf.id_produto AND p.filial_id = tcf.filial_id;

    $f$, p_schema_name, filial_filter_clause);

    EXECUTE dyn_sql;

    PERFORM public.log_job('atualizar_curva_lucro', p_schema_name, 'SUCCESS', 'Filiais: ' || COALESCE(p_filiais_ids::text, 'TODAS'), start_time);

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job('atualizar_curva_lucro', p_schema_name, 'ERROR', SQLERRM, start_time);
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_curva_lucro_30d(p_schema_name text, p_filiais_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    dyn_sql text;
    start_time timestamptz := clock_timestamp();
    filial_filter_clause text := '';
BEGIN
    IF p_filiais_ids IS NOT NULL AND array_length(p_filiais_ids, 1) > 0 THEN
        filial_filter_clause := format('AND p.filial_id = ANY(%L)', p_filiais_ids);
    END IF;

    dyn_sql := format($f$
        CREATE TEMP TABLE temp_curva_lucro_final (
            id_produto bigint,
            filial_id bigint,
            curva_final varchar(2)
        ) ON COMMIT DROP;

        WITH
        calculo_base AS (
            SELECT
                p.filial_id,
                p.departamento_id,
                p.id as id_produto,
                COALESCE(SUM(v.valor_vendas - (v.quantidade * p.custo_medio)), 0) as total_lucro_produto,
                SUM(COALESCE(SUM(v.valor_vendas - (v.quantidade * p.custo_medio)), 0)) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_lucro_departamento,
                ROW_NUMBER() OVER (PARTITION BY p.filial_id, p.departamento_id ORDER BY COALESCE(SUM(v.valor_vendas - (v.quantidade * p.custo_medio)), 0) DESC) as ranking,
                COUNT(*) OVER (PARTITION BY p.filial_id, p.departamento_id) as total_produtos_no_grupo
            FROM
                %1$I.produtos p
            LEFT JOIN
                %1$I.vendas v ON p.id = v.id_produto
                                AND p.filial_id = v.filial_id
                                AND v.data_venda >= (CURRENT_DATE - INTERVAL '30 days')
                                AND v.data_venda < CURRENT_DATE
            WHERE
                p.ativo = true
                %2$s
            GROUP BY
                p.filial_id, p.departamento_id, p.id
        ),
        calculo_curva_inicial AS (
            SELECT
                *,
                SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as acumulado,
                CASE
                    WHEN total_lucro_produto <= 0 THEN 'SL'
                    WHEN (total_lucro_produto / NULLIF(total_lucro_departamento, 0)) > 0.50 THEN 'A'
                    WHEN (SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_lucro_departamento, 0)) <= 0.51 THEN 'A'
                    WHEN (SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_lucro_departamento, 0)) <= 0.81 THEN 'B'
                    WHEN (SUM(total_lucro_produto) OVER (PARTITION BY filial_id, departamento_id ORDER BY ranking ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / NULLIF(total_lucro_departamento, 0)) <= 0.91 THEN 'C'
                    ELSE 'D'
                END AS curva_inicial
            FROM
                calculo_base
        ),
        analise_de_presenca AS (
            SELECT
                *,
                BOOL_OR(curva_inicial = 'A') OVER (PARTITION BY filial_id, departamento_id) as tem_A,
                BOOL_OR(curva_inicial = 'B') OVER (PARTITION BY filial_id, departamento_id) as tem_B,
                BOOL_OR(curva_inicial = 'C') OVER (PARTITION BY filial_id, departamento_id) as tem_C
            FROM
                calculo_curva_inicial
        )
        INSERT INTO temp_curva_lucro_final (id_produto, filial_id, curva_final)
        SELECT
            id_produto,
            filial_id,
            CASE
                WHEN curva_inicial = 'SL' THEN 'SL'
                WHEN total_produtos_no_grupo = 1 THEN 'A'
                WHEN tem_A = false AND ranking = 1 THEN 'A'
                WHEN tem_B = false AND ranking = 2 AND total_produtos_no_grupo >= 2 THEN 'B'
                WHEN tem_C = false AND ranking = 3 AND total_produtos_no_grupo >= 3 THEN 'C'
                ELSE curva_inicial
            END AS curva_final
        FROM
            analise_de_presenca;

        UPDATE %1$I.produtos p
        SET curva_lucro = tcf.curva_final
        FROM temp_curva_lucro_final tcf
        WHERE p.id = tcf.id_produto AND p.filial_id = tcf.filial_id;

    $f$, p_schema_name, filial_filter_clause);

    EXECUTE dyn_sql;

    PERFORM public.log_job('atualizar_curva_lucro_30d', p_schema_name, 'SUCCESS', 'Filiais: ' || COALESCE(p_filiais_ids::text, 'TODAS'), start_time);

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job('atualizar_curva_lucro_30d', p_schema_name, 'ERROR', SQLERRM, start_time);
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_despesas_diarias(p_schema_name text, p_data_inicial date, p_data_final date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    EXECUTE format('
        DELETE FROM %I.despesas_diarias_por_filial
        WHERE data_referencia BETWEEN $1 AND $2
    ', p_schema_name)
    USING p_data_inicial, p_data_final;

    EXECUTE format('
        INSERT INTO %I.despesas_diarias_por_filial (
            filial_id,
            data_referencia,
            total_valor,
            quantidade_lancamentos,
            updated_at
        )
        SELECT
            d.filial_id,
            d.data_despesa,
            SUM(d.valor),
            COUNT(*),
            NOW()
        FROM %I.despesas d
        WHERE d.data_despesa BETWEEN $1 AND $2
        GROUP BY d.filial_id, d.data_despesa
    ', p_schema_name, p_schema_name)
    USING p_data_inicial, p_data_final;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_dias_com_venda_60d(schema_name text, p_filiais integer[] DEFAULT NULL::integer[])
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  start_time timestamptz := clock_timestamp();
  v_filiais_msg text;
BEGIN
  SET statement_timeout = '600s';

  v_filiais_msg := COALESCE(p_filiais::text, 'TODAS');

  EXECUTE format('
    WITH produtos_ativos AS (
      SELECT id, filial_id
      FROM %I.produtos
      WHERE venda_media_diaria_60d > 0
        AND ($1 IS NULL OR filial_id = ANY($1))
    ),
    calculo_dias_60d AS (
      SELECT
        v.id_produto,
        v.filial_id,
        COUNT(DISTINCT v.data_venda) AS total_dias_60d
      FROM %I.vendas v
      JOIN produtos_ativos pa ON v.id_produto = pa.id AND v.filial_id = pa.filial_id
      WHERE
        v.data_venda >= (CURRENT_DATE - INTERVAL ''63 days'')
        AND v.data_venda < (CURRENT_DATE - INTERVAL ''3 days'')
        AND ($1 IS NULL OR v.filial_id = ANY($1))
      GROUP BY v.id_produto, v.filial_id
    ),
    calculo_dias_3d AS (
      SELECT
        v.id_produto,
        v.filial_id,
        COUNT(DISTINCT v.data_venda) AS total_dias_3d
      FROM %I.vendas v
      JOIN produtos_ativos pa ON v.id_produto = pa.id AND v.filial_id = pa.filial_id
      WHERE
        v.data_venda >= (CURRENT_DATE - INTERVAL ''3 days'')
        AND v.data_venda < CURRENT_DATE
        AND ($1 IS NULL OR v.filial_id = ANY($1))
      GROUP BY v.id_produto, v.filial_id
    )
    UPDATE %I.produtos p
    SET
      dias_com_venda_60d = COALESCE(cd60.total_dias_60d, 0),
      dias_com_venda_ultimos_3d = COALESCE(cd3.total_dias_3d, 0)
    FROM produtos_ativos pa
    LEFT JOIN calculo_dias_60d cd60 ON pa.id = cd60.id_produto AND pa.filial_id = cd60.filial_id
    LEFT JOIN calculo_dias_3d cd3 ON pa.id = cd3.id_produto AND pa.filial_id = cd3.filial_id
    WHERE
      p.id = pa.id
      AND p.filial_id = pa.filial_id
      AND ($1 IS NULL OR p.filial_id = ANY($1));

    UPDATE %I.produtos
    SET
      dias_com_venda_60d = 0,
      dias_com_venda_ultimos_3d = 0
    WHERE COALESCE(venda_media_diaria_60d, 0) <= 0
      AND ($1 IS NULL OR filial_id = ANY($1));
  ', schema_name, schema_name, schema_name, schema_name, schema_name) USING p_filiais;

  PERFORM public.log_job(
      'atualizar_dias_com_venda_60d',
      schema_name,
      'SUCCESS',
      'Dias com venda (60d e 3d) atualizados. Filiais: ' || v_filiais_msg,
      start_time
  );

  RETURN 'Contagem de dias com venda concluida para ' || schema_name || ' - Filiais: ' || v_filiais_msg;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job(
            'atualizar_dias_com_venda_60d',
            schema_name,
            'ERROR',
            SQLERRM || ' - Filiais: ' || v_filiais_msg,
            start_time
        );
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_dias_com_venda_60d_batch(schema_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  start_time timestamptz := clock_timestamp();
  batch_size INT := 5000;
  offset_val INT := 0;
  total_produtos INT;
  rows_affected INT;
  data_inicio DATE := CURRENT_DATE - INTERVAL '59 days';
BEGIN
  SET statement_timeout = '600s';

  EXECUTE format('SELECT COUNT(*) FROM %I.produtos WHERE venda_media_diaria_60d > 0', schema_name)
  INTO total_produtos;

  RAISE NOTICE 'Total de produtos a processar: %', total_produtos;

  LOOP
    EXECUTE format('
      WITH produtos_batch AS (
        SELECT id, filial_id
        FROM %I.produtos
        WHERE venda_media_diaria_60d > 0
        ORDER BY id, filial_id
        LIMIT $1 OFFSET $2
      ),
      calculo_dias AS (
        SELECT
          v.id_produto,
          v.filial_id,
          COUNT(DISTINCT DATE(v.data_venda)) AS total_dias
        FROM %I.vendas v
        INNER JOIN produtos_batch pb
          ON v.id_produto = pb.id
          AND v.filial_id = pb.filial_id
        WHERE v.data_venda >= $3
          AND v.data_venda < CURRENT_DATE
        GROUP BY v.id_produto, v.filial_id
      )
      UPDATE %I.produtos p
      SET dias_com_venda_60d = COALESCE(cd.total_dias, 0),
          updated_at = NOW()
      FROM produtos_batch pb
      LEFT JOIN calculo_dias cd
        ON pb.id = cd.id_produto
        AND pb.filial_id = cd.filial_id
      WHERE p.id = pb.id
        AND p.filial_id = pb.filial_id
    ', schema_name, schema_name, schema_name)
    USING batch_size, offset_val, data_inicio;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    EXIT WHEN rows_affected = 0;

    offset_val := offset_val + batch_size;
    RAISE NOTICE 'Processados: %/%', offset_val, total_produtos;

    COMMIT;
  END LOOP;

  EXECUTE format('
    UPDATE %I.produtos
    SET dias_com_venda_60d = 0, updated_at = NOW()
    WHERE COALESCE(venda_media_diaria_60d, 0) <= 0
      AND COALESCE(dias_com_venda_60d, 0) != 0
  ', schema_name);

  RETURN format('Concluido: %s produtos em %s',
    total_produtos,
    clock_timestamp() - start_time
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_dias_de_estoque(schema_name text, p_filiais integer[] DEFAULT NULL::integer[])
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  start_time timestamptz := clock_timestamp();
  rows_updated INT;
  v_filiais_msg text;
BEGIN
  SET LOCAL statement_timeout = '300s';
  SET LOCAL work_mem = '512MB';

  v_filiais_msg := COALESCE(p_filiais::text, 'TODAS');

  EXECUTE format('
    UPDATE %I.produtos
    SET dias_de_estoque = estoque_atual / venda_media_diaria_60d
    WHERE venda_media_diaria_60d > 0
      AND COALESCE(estoque_atual, 0) > 0
      AND ($1 IS NULL OR filial_id = ANY($1))
  ', schema_name) USING p_filiais;

  GET DIAGNOSTICS rows_updated = ROW_COUNT;

  EXECUTE format('
    UPDATE %I.produtos
    SET dias_de_estoque = 0
    WHERE venda_media_diaria_60d > 0
      AND (estoque_atual IS NULL OR estoque_atual <= 0)
      AND ($1 IS NULL OR filial_id = ANY($1))
  ', schema_name) USING p_filiais;

  PERFORM public.log_job(
      'atualizar_dias_de_estoque',
      schema_name,
      'SUCCESS',
      format('%s produtos atualizados - Filiais: %s', rows_updated, v_filiais_msg),
      start_time
  );

  RETURN format('%s produtos atualizados em %s segundos - Filiais: %s',
                rows_updated,
                EXTRACT(EPOCH FROM (clock_timestamp() - start_time))::INT,
                v_filiais_msg);

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job(
            'atualizar_dias_de_estoque',
            schema_name,
            'ERROR',
            SQLERRM || ' - Filiais: ' || v_filiais_msg,
            start_time
        );
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_metricas_dias_com_venda_60d(schema_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  start_time timestamptz := clock_timestamp();
BEGIN
  SET statement_timeout = '900s';

  EXECUTE format('REFRESH MATERIALIZED VIEW CONCURRENTLY %I.metricas_dias_com_vendas_60d;', schema_name);

  PERFORM public.log_job(
      'atualizar_metricas_dias_com_venda_60d', schema_name, 'SUCCESS',
      'Materialized View de dias com venda (60d) foi atualizada.', start_time
  );
  RETURN 'Materialized View atualizada para o schema ' || schema_name;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job(
            'atualizar_metricas_dias_com_venda_60d', schema_name, 'ERROR',
            SQLERRM, start_time
        );
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_metricas_por_filial(schema_name text, p_filial_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '600s'
AS $function$
BEGIN
  EXECUTE format('UPDATE %I.produtos SET venda_media_diaria_60d = 0, dias_de_estoque = NULL, dias_com_venda_60d = 0 WHERE filial_id = $1;', schema_name) USING p_filial_id;
  EXECUTE format('WITH vendas_recentes AS (SELECT v.id_produto, v.filial_id, SUM(v.quantidade) AS total_vendido_60d, COUNT(DISTINCT v.data_venda) AS dias_com_venda FROM %I.vendas AS v WHERE v.data_venda >= (CURRENT_DATE - INTERVAL ''60 days'') AND v.filial_id = $1 GROUP BY v.id_produto, v.filial_id) UPDATE %I.produtos AS p SET dias_com_venda_60d = vr.dias_com_venda, venda_media_diaria_60d = vr.total_vendido_60d / 60.0, dias_de_estoque = CASE WHEN vr.total_vendido_60d > 0 THEN p.estoque_atual / (vr.total_vendido_60d / 60.0) ELSE NULL END FROM vendas_recentes AS vr WHERE p.id = vr.id_produto AND p.filial_id = vr.filial_id;', schema_name, schema_name) USING p_filial_id;
  RETURN 'Metricas de produto atualizadas para o schema ' || schema_name || ' e filial ' || p_filial_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_produtos_com_dias_de_venda(schema_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  start_time timestamptz := clock_timestamp();
BEGIN
  SET statement_timeout = '300s';

  EXECUTE format('
    UPDATE
        %I.produtos p
    SET
        dias_com_venda_60d = mv.dias_com_venda_60d
    FROM
        %I.metricas_dias_com_vendas_60d mv
    WHERE
        p.id = mv.id_produto
        AND p.filial_id = mv.filial_id;

    UPDATE
        %I.produtos
    SET
        dias_com_venda_60d = 0
    WHERE
        dias_com_venda_60d IS NULL;

  ', schema_name, schema_name, schema_name);

  PERFORM public.log_job(
      'atualizar_produtos_com_dias_de_venda', schema_name, 'SUCCESS',
      'Coluna dias_com_venda_60d foi sincronizada na tabela de produtos.', start_time
  );
  RETURN 'Coluna dias_com_venda_60d na tabela de produtos foi atualizada para o schema ' || schema_name;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM public.log_job(
            'atualizar_produtos_com_dias_de_venda', schema_name, 'ERROR',
            SQLERRM, start_time
        );
        RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_resumo_vendas_caixa(p_schema_name text, p_data date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    EXECUTE format('
        INSERT INTO %I.resumo_vendas_caixa (filial_id, caixa, data, qtde_cupons, qtde_produtos, valor_total_vendas, valor_total_vendas_canceladas, valor_total_produtos_cancelados, updated_at)
        WITH cupons_resumo AS (
            SELECT
                filial_id,
                caixa,
                cupom,
                cancelada,
                valor_total
            FROM %I.vendas_hoje
        ),
        itens_resumo AS (
            SELECT
                filial_id,
                cupom,
                SUM(CASE WHEN NOT cancelado THEN quantidade_vendida ELSE 0 END) AS qtde_produtos,
                SUM(CASE WHEN cancelado THEN quantidade_vendida * preco_venda ELSE 0 END) AS valor_produtos_cancelados
            FROM %I.vendas_hoje_itens
            GROUP BY filial_id, cupom
        )
        SELECT
            c.filial_id,
            c.caixa,
            $1 AS data,
            COUNT(DISTINCT c.cupom)::INTEGER AS qtde_cupons,
            COALESCE(SUM(CASE WHEN NOT c.cancelada THEN i.qtde_produtos ELSE 0 END), 0)::INTEGER AS qtde_produtos,
            COALESCE(SUM(CASE WHEN NOT c.cancelada THEN c.valor_total ELSE 0 END), 0) AS valor_total_vendas,
            COALESCE(SUM(CASE WHEN c.cancelada THEN c.valor_total ELSE 0 END), 0) AS valor_total_vendas_canceladas,
            COALESCE(SUM(CASE WHEN NOT c.cancelada THEN i.valor_produtos_cancelados ELSE 0 END), 0) AS valor_total_produtos_cancelados,
            NOW()
        FROM cupons_resumo c
        LEFT JOIN itens_resumo i ON c.filial_id = i.filial_id AND c.cupom = i.cupom
        GROUP BY c.filial_id, c.caixa
        ON CONFLICT (filial_id, caixa, data) DO UPDATE SET
            qtde_cupons = EXCLUDED.qtde_cupons,
            qtde_produtos = EXCLUDED.qtde_produtos,
            valor_total_vendas = EXCLUDED.valor_total_vendas,
            valor_total_vendas_canceladas = EXCLUDED.valor_total_vendas_canceladas,
            valor_total_produtos_cancelados = EXCLUDED.valor_total_produtos_cancelados,
            updated_at = NOW()
    ', p_schema_name, p_schema_name, p_schema_name) USING p_data;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_valores_realizados_metas(p_schema text, p_mes integer, p_ano integer, p_filial_id bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_data_inicio date;
  v_data_fim date;
  v_rows_updated integer := 0;
  v_message text;
BEGIN
  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := (v_data_inicio + interval '1 month' - interval '1 day')::date;

  IF p_filial_id IS NULL THEN
    EXECUTE format('
      UPDATE %I.metas_mensais mm
      SET
        valor_realizado = (
          COALESCE((
            SELECT SUM(v.valor_vendas)
            FROM %I.vendas v
            WHERE v.data_venda = mm.data
              AND v.filial_id = mm.filial_id
          ), 0) - COALESCE((
            SELECT SUM(d.valor_desconto)
            FROM %I.descontos_venda d
            WHERE d.data_desconto = mm.data
              AND d.filial_id = mm.filial_id
          ), 0)
        ),
        custo_realizado = COALESCE((
          SELECT SUM(v.quantidade * v.custo_compra)
          FROM %I.vendas v
          WHERE v.data_venda = mm.data
            AND v.filial_id = mm.filial_id
        ), 0),
        lucro_realizado = (
          COALESCE((
            SELECT SUM(v.valor_vendas)
            FROM %I.vendas v
            WHERE v.data_venda = mm.data
              AND v.filial_id = mm.filial_id
          ), 0) - COALESCE((
            SELECT SUM(d.valor_desconto)
            FROM %I.descontos_venda d
            WHERE d.data_desconto = mm.data
              AND d.filial_id = mm.filial_id
          ), 0)
        ) - COALESCE((
          SELECT SUM(v.quantidade * v.custo_compra)
          FROM %I.vendas v
          WHERE v.data_venda = mm.data
            AND v.filial_id = mm.filial_id
        ), 0),
        diferenca = (
          (COALESCE((
            SELECT SUM(v.valor_vendas)
            FROM %I.vendas v
            WHERE v.data_venda = mm.data
              AND v.filial_id = mm.filial_id
          ), 0) - COALESCE((
            SELECT SUM(d.valor_desconto)
            FROM %I.descontos_venda d
            WHERE d.data_desconto = mm.data
              AND d.filial_id = mm.filial_id
          ), 0)) - mm.valor_meta
        ),
        diferenca_percentual = CASE
          WHEN mm.valor_meta > 0 THEN
            ((((COALESCE((
              SELECT SUM(v.valor_vendas)
              FROM %I.vendas v
              WHERE v.data_venda = mm.data
                AND v.filial_id = mm.filial_id
            ), 0) - COALESCE((
              SELECT SUM(d.valor_desconto)
              FROM %I.descontos_venda d
              WHERE d.data_desconto = mm.data
                AND d.filial_id = mm.filial_id
            ), 0)) - mm.valor_meta) / mm.valor_meta) * 100)
          ELSE 0
        END,
        updated_at = NOW()
      WHERE mm.data >= $1
        AND mm.data <= $2
    ', p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema)
    USING v_data_inicio, v_data_fim;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    v_message := format('Valores atualizados com sucesso para %s metas', v_rows_updated);
  ELSE
    EXECUTE format('
      UPDATE %I.metas_mensais mm
      SET
        valor_realizado = (
          COALESCE((
            SELECT SUM(v.valor_vendas)
            FROM %I.vendas v
            WHERE v.data_venda = mm.data
              AND v.filial_id = mm.filial_id
          ), 0) - COALESCE((
            SELECT SUM(d.valor_desconto)
            FROM %I.descontos_venda d
            WHERE d.data_desconto = mm.data
              AND d.filial_id = mm.filial_id
          ), 0)
        ),
        custo_realizado = COALESCE((
          SELECT SUM(v.quantidade * v.custo_compra)
          FROM %I.vendas v
          WHERE v.data_venda = mm.data
            AND v.filial_id = mm.filial_id
        ), 0),
        lucro_realizado = (
          COALESCE((
            SELECT SUM(v.valor_vendas)
            FROM %I.vendas v
            WHERE v.data_venda = mm.data
              AND v.filial_id = mm.filial_id
          ), 0) - COALESCE((
            SELECT SUM(d.valor_desconto)
            FROM %I.descontos_venda d
            WHERE d.data_desconto = mm.data
              AND d.filial_id = mm.filial_id
          ), 0)
        ) - COALESCE((
          SELECT SUM(v.quantidade * v.custo_compra)
          FROM %I.vendas v
          WHERE v.data_venda = mm.data
            AND v.filial_id = mm.filial_id
        ), 0),
        diferenca = (
          (COALESCE((
            SELECT SUM(v.valor_vendas)
            FROM %I.vendas v
            WHERE v.data_venda = mm.data
              AND v.filial_id = mm.filial_id
          ), 0) - COALESCE((
            SELECT SUM(d.valor_desconto)
            FROM %I.descontos_venda d
            WHERE d.data_desconto = mm.data
              AND d.filial_id = mm.filial_id
          ), 0)) - mm.valor_meta
        ),
        diferenca_percentual = CASE
          WHEN mm.valor_meta > 0 THEN
            ((((COALESCE((
              SELECT SUM(v.valor_vendas)
              FROM %I.vendas v
              WHERE v.data_venda = mm.data
                AND v.filial_id = mm.filial_id
            ), 0) - COALESCE((
              SELECT SUM(d.valor_desconto)
              FROM %I.descontos_venda d
              WHERE d.data_desconto = mm.data
                AND d.filial_id = mm.filial_id
            ), 0)) - mm.valor_meta) / mm.valor_meta) * 100)
          ELSE 0
        END,
        updated_at = NOW()
      WHERE mm.data >= $1
        AND mm.data <= $2
        AND mm.filial_id = $3
    ', p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema)
    USING v_data_inicio, v_data_fim, p_filial_id;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    v_message := format('Valores atualizados com sucesso para %s metas da filial %s', v_rows_updated, p_filial_id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', v_message,
    'rows_updated', v_rows_updated,
    'periodo', jsonb_build_object(
      'mes', p_mes,
      'ano', p_ano,
      'data_inicio', v_data_inicio,
      'data_fim', v_data_fim
    )
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Erro ao atualizar valores: ' || SQLERRM,
      'rows_updated', 0
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_valores_realizados_metas_setor(p_schema text, p_setor_id bigint, p_mes integer, p_ano integer, p_filial_id bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '90s'
 SET work_mem TO '256MB'
AS $function$
DECLARE
  v_departamento_nivel INT;
  v_departamento_ids BIGINT[];
  v_coluna_pai TEXT;
  v_sql TEXT;
  v_rows_updated INT;
  v_schema_quoted TEXT;
  v_date_start DATE;
  v_date_end DATE;
  v_query_start TIMESTAMP;
  v_query_duration INTERVAL;
BEGIN
  v_query_start := clock_timestamp();

  IF p_schema IS NULL OR p_setor_id IS NULL OR p_mes IS NULL OR p_ano IS NULL THEN
    RETURN jsonb_build_object(
      'error', true,
      'message', 'Schema, setor_id, mes e ano sao obrigatorios'
    );
  END IF;

  v_schema_quoted := quote_ident(p_schema);

  v_date_start := make_date(p_ano, p_mes, 1);
  v_date_end := v_date_start + INTERVAL '1 month' - INTERVAL '1 day';

  EXECUTE format('
    SELECT departamento_nivel, departamento_ids
    FROM %I.setores
    WHERE id = $1 AND ativo = true
  ', p_schema)
  INTO v_departamento_nivel, v_departamento_ids
  USING p_setor_id;

  IF v_departamento_nivel IS NULL THEN
    RETURN jsonb_build_object(
      'error', true,
      'message', format('Setor %s nao encontrado ou inativo', p_setor_id)
    );
  END IF;

  IF v_departamento_ids IS NULL OR array_length(v_departamento_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'error', true,
      'message', format('Setor %s nao tem departamentos configurados', p_setor_id),
      'rows_updated', 0,
      'setor_id', p_setor_id
    );
  END IF;

  v_coluna_pai := format('pai_level_%s_id', v_departamento_nivel);

  v_sql := format('
    WITH vendas_por_data_filial AS (
      SELECT
        v.data_venda,
        v.filial_id,
        SUM(v.valor_vendas) - COALESCE(SUM(d.valor_desconto), 0) AS total_vendas,
        SUM(v.quantidade * v.custo_compra) AS total_custo,
        (SUM(v.valor_vendas) - COALESCE(SUM(d.valor_desconto), 0)) - SUM(v.quantidade * v.custo_compra) AS total_lucro
      FROM %I.vendas v
      INNER JOIN %I.produtos p
        ON p.id = v.id_produto
        AND p.filial_id = v.filial_id
      INNER JOIN %I.departments_level_1 dl1
        ON dl1.departamento_id = p.departamento_id
        AND dl1.%I = ANY($1)
      LEFT JOIN %I.descontos_venda d
        ON d.data_desconto = v.data_venda
        AND d.filial_id = v.filial_id
      WHERE
        v.data_venda >= $2
        AND v.data_venda <= $3
        AND ($4 IS NULL OR v.filial_id = $4)
      GROUP BY v.data_venda, v.filial_id
    )
    UPDATE %I.metas_setor ms
    SET
      valor_realizado = COALESCE(vpd.total_vendas, 0),
      custo_realizado = COALESCE(vpd.total_custo, 0),
      lucro_realizado = COALESCE(vpd.total_lucro, 0),
      diferenca = COALESCE(vpd.total_vendas, 0) - ms.valor_meta,
      diferenca_percentual = CASE
        WHEN ms.valor_meta > 0 THEN
          ((COALESCE(vpd.total_vendas, 0) / ms.valor_meta) - 1) * 100
        ELSE 0
      END,
      updated_at = NOW()
    FROM vendas_por_data_filial vpd
    WHERE
      ms.setor_id = $5
      AND ms.data = vpd.data_venda
      AND ms.filial_id = vpd.filial_id
      AND (
        ms.valor_realizado IS DISTINCT FROM COALESCE(vpd.total_vendas, 0)
        OR ms.custo_realizado IS DISTINCT FROM COALESCE(vpd.total_custo, 0)
        OR ms.lucro_realizado IS DISTINCT FROM COALESCE(vpd.total_lucro, 0)
      )
  ',
    p_schema,
    p_schema,
    p_schema,
    v_coluna_pai,
    p_schema,
    p_schema
  );

  EXECUTE v_sql
  USING v_departamento_ids, v_date_start, v_date_end, p_filial_id, p_setor_id;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  v_query_duration := clock_timestamp() - v_query_start;

  RETURN jsonb_build_object(
    'rows_updated', v_rows_updated,
    'setor_id', p_setor_id,
    'mes', p_mes,
    'ano', p_ano,
    'filial_id', p_filial_id,
    'duration_ms', EXTRACT(EPOCH FROM v_query_duration) * 1000
  );

EXCEPTION
  WHEN query_canceled THEN
    RETURN jsonb_build_object(
      'error', true,
      'message', 'Timeout ao atualizar valores (>90s). Verifique se os indices foram criados.',
      'setor_id', p_setor_id,
      'timeout', true
    );
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'error', true,
      'message', SQLERRM,
      'detail', SQLSTATE,
      'setor_id', p_setor_id
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_valores_realizados_todos_setores(p_schema text, p_mes integer, p_ano integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '180s'
 SET work_mem TO '512MB'
AS $function$
DECLARE
  v_date_start DATE;
  v_date_end DATE;
  v_query_start TIMESTAMP;
  v_query_duration INTERVAL;
  v_total_rows INT := 0;
  v_total_setores INT := 0;
  v_errors TEXT[] := ARRAY[]::TEXT[];
  v_update_sql TEXT;
BEGIN
  v_query_start := clock_timestamp();

  IF p_schema IS NULL OR p_mes IS NULL OR p_ano IS NULL THEN
    RAISE EXCEPTION 'Schema, mes e ano sao obrigatorios';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mes invalido: %', p_mes;
  END IF;

  v_date_start := make_date(p_ano, p_mes, 1);
  v_date_end := v_date_start + INTERVAL '1 month' - INTERVAL '1 day';

  v_update_sql := format('
    WITH setores_ativos AS (
      SELECT
        id AS setor_id,
        nome AS setor_nome,
        departamento_nivel,
        departamento_ids
      FROM %I.setores
      WHERE ativo = true
    ),
    vendas_por_setor AS (
      SELECT
        sa.setor_id,
        v.data_venda,
        v.filial_id,
        SUM(v.valor_vendas) AS total_vendas,
        SUM(v.quantidade * v.custo_compra) AS total_custo,
        SUM(v.valor_vendas) - SUM(v.quantidade * v.custo_compra) AS total_lucro
      FROM setores_ativos sa
      INNER JOIN %I.departments_level_1 dl1
        ON dl1.pai_level_2_id = ANY(sa.departamento_ids)
        AND sa.departamento_nivel = 2
      INNER JOIN %I.produtos p
        ON p.departamento_id = dl1.departamento_id
      INNER JOIN %I.vendas v
        ON v.id_produto = p.id
        AND v.filial_id = p.filial_id
        AND v.data_venda >= $1
        AND v.data_venda <= $2
      WHERE sa.departamento_nivel = 2
      GROUP BY sa.setor_id, v.data_venda, v.filial_id

      UNION ALL

      SELECT
        sa.setor_id,
        v.data_venda,
        v.filial_id,
        SUM(v.valor_vendas) AS total_vendas,
        SUM(v.quantidade * v.custo_compra) AS total_custo,
        SUM(v.valor_vendas) - SUM(v.quantidade * v.custo_compra) AS total_lucro
      FROM setores_ativos sa
      INNER JOIN %I.departments_level_1 dl1
        ON dl1.pai_level_3_id = ANY(sa.departamento_ids)
        AND sa.departamento_nivel = 3
      INNER JOIN %I.produtos p
        ON p.departamento_id = dl1.departamento_id
      INNER JOIN %I.vendas v
        ON v.id_produto = p.id
        AND v.filial_id = p.filial_id
        AND v.data_venda >= $1
        AND v.data_venda <= $2
      WHERE sa.departamento_nivel = 3
      GROUP BY sa.setor_id, v.data_venda, v.filial_id

      UNION ALL

      SELECT
        sa.setor_id,
        v.data_venda,
        v.filial_id,
        SUM(v.valor_vendas) AS total_vendas,
        SUM(v.quantidade * v.custo_compra) AS total_custo,
        SUM(v.valor_vendas) - SUM(v.quantidade * v.custo_compra) AS total_lucro
      FROM setores_ativos sa
      INNER JOIN %I.departments_level_1 dl1
        ON dl1.pai_level_4_id = ANY(sa.departamento_ids)
        AND sa.departamento_nivel = 4
      INNER JOIN %I.produtos p
        ON p.departamento_id = dl1.departamento_id
      INNER JOIN %I.vendas v
        ON v.id_produto = p.id
        AND v.filial_id = p.filial_id
        AND v.data_venda >= $1
        AND v.data_venda <= $2
      WHERE sa.departamento_nivel = 4
      GROUP BY sa.setor_id, v.data_venda, v.filial_id

      UNION ALL

      SELECT
        sa.setor_id,
        v.data_venda,
        v.filial_id,
        SUM(v.valor_vendas) AS total_vendas,
        SUM(v.quantidade * v.custo_compra) AS total_custo,
        SUM(v.valor_vendas) - SUM(v.quantidade * v.custo_compra) AS total_lucro
      FROM setores_ativos sa
      INNER JOIN %I.departments_level_1 dl1
        ON dl1.pai_level_5_id = ANY(sa.departamento_ids)
        AND sa.departamento_nivel = 5
      INNER JOIN %I.produtos p
        ON p.departamento_id = dl1.departamento_id
      INNER JOIN %I.vendas v
        ON v.id_produto = p.id
        AND v.filial_id = p.filial_id
        AND v.data_venda >= $1
        AND v.data_venda <= $2
      WHERE sa.departamento_nivel = 5
      GROUP BY sa.setor_id, v.data_venda, v.filial_id

      UNION ALL

      SELECT
        sa.setor_id,
        v.data_venda,
        v.filial_id,
        SUM(v.valor_vendas) AS total_vendas,
        SUM(v.quantidade * v.custo_compra) AS total_custo,
        SUM(v.valor_vendas) - SUM(v.quantidade * v.custo_compra) AS total_lucro
      FROM setores_ativos sa
      INNER JOIN %I.departments_level_1 dl1
        ON dl1.pai_level_6_id = ANY(sa.departamento_ids)
        AND sa.departamento_nivel = 6
      INNER JOIN %I.produtos p
        ON p.departamento_id = dl1.departamento_id
      INNER JOIN %I.vendas v
        ON v.id_produto = p.id
        AND v.filial_id = p.filial_id
        AND v.data_venda >= $1
        AND v.data_venda <= $2
      WHERE sa.departamento_nivel = 6
      GROUP BY sa.setor_id, v.data_venda, v.filial_id
    ),
    setores_contados AS (
      SELECT COUNT(DISTINCT id) AS total
      FROM %I.setores
      WHERE ativo = true
    )
    UPDATE %I.metas_setor ms
    SET
      valor_realizado = COALESCE(vps.total_vendas, 0),
      custo_realizado = COALESCE(vps.total_custo, 0),
      lucro_realizado = COALESCE(vps.total_lucro, 0),
      diferenca = COALESCE(vps.total_vendas, 0) - ms.valor_meta,
      diferenca_percentual = CASE
        WHEN ms.valor_meta > 0 THEN
          ((COALESCE(vps.total_vendas, 0) / ms.valor_meta) - 1) * 100
        ELSE 0
      END,
      updated_at = NOW()
    FROM vendas_por_setor vps
    WHERE
      ms.setor_id = vps.setor_id
      AND ms.data = vps.data_venda
      AND ms.filial_id = vps.filial_id
      AND (
        ms.valor_realizado IS DISTINCT FROM COALESCE(vps.total_vendas, 0)
        OR ms.custo_realizado IS DISTINCT FROM COALESCE(vps.total_custo, 0)
        OR ms.lucro_realizado IS DISTINCT FROM COALESCE(vps.total_lucro, 0)
      )
    RETURNING (SELECT total FROM setores_contados)
  ',
    p_schema,
    p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema,
    p_schema,
    p_schema
  );

  BEGIN
    EXECUTE v_update_sql
    USING v_date_start, v_date_end
    INTO v_total_setores;

    GET DIAGNOSTICS v_total_rows = ROW_COUNT;

  EXCEPTION WHEN OTHERS THEN
    v_errors := array_append(v_errors, format('Erro no UPDATE em massa: %s', SQLERRM));
    RAISE WARNING 'Erro ao processar UPDATE em massa: %', SQLERRM;
  END;

  v_query_duration := clock_timestamp() - v_query_start;

  RETURN json_build_object(
    'success', true,
    'message', format('Processados %s setores, %s metas atualizadas (sem desconto)', COALESCE(v_total_setores, 0), v_total_rows),
    'rows_updated', v_total_rows,
    'setores_processados', COALESCE(v_total_setores, 0),
    'errors', v_errors,
    'timestamp', NOW(),
    'duration_ms', EXTRACT(EPOCH FROM v_query_duration) * 1000,
    'strategy', 'UNION ALL (batch update) sem desconto'
  );

EXCEPTION
  WHEN query_canceled THEN
    RAISE EXCEPTION 'Timeout ao atualizar valores (>180s). Considere executar em horario de baixo trafego.';
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Erro ao atualizar valores: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_vendas_diarias(p_schema_name text, p_data_inicial date, p_data_final date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    EXECUTE format('
        DELETE FROM %I.vendas_diarias_por_filial
        WHERE data_venda BETWEEN $1 AND $2
    ', p_schema_name)
    USING p_data_inicial, p_data_final;

    EXECUTE format('
        INSERT INTO %I.vendas_diarias_por_filial (
            filial_id,
            data_venda,
            valor_total,
            quantidade_total,
            total_transacoes,
            custo_total,
            total_lucro
        )
        SELECT
            v.filial_id,
            v.data_venda,
            SUM(v.valor_vendas) AS valor_total,
            SUM(v.quantidade) AS quantidade_total,
            COUNT(*) AS total_transacoes,
            SUM(v.quantidade * v.custo_compra) AS custo_total,
            SUM(v.valor_vendas) - SUM(v.quantidade * v.custo_compra) AS total_lucro
        FROM %I.vendas v
        WHERE v.data_venda BETWEEN $1 AND $2
        GROUP BY v.filial_id, v.data_venda
    ', p_schema_name, p_schema_name)
    USING p_data_inicial, p_data_final;
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_vendas_por_departamento(p_schema text, p_data_inicio date, p_data_fim date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_rows_inserted INTEGER := 0;
  v_nivel INT;
BEGIN
  EXECUTE format('DELETE FROM %I.vendas_por_departamento WHERE data BETWEEN $1 AND $2', p_schema)
  USING p_data_inicio, p_data_fim;

  FOR v_nivel IN 1..6 LOOP
    EXECUTE format('
      INSERT INTO %I.vendas_por_departamento
        (data, filial_id, departamento_nivel, departamento_id, valor_total, quantidade_vendas)
      SELECT
        DATE(v.data_venda),
        v.filial_id,
        %s,
        p.departamento_%s_id,
        SUM(v.valor_vendas),
        COUNT(*)
      FROM %I.vendas v
      INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
      WHERE v.data_venda BETWEEN $1 AND $2
        AND p.departamento_%s_id IS NOT NULL
      GROUP BY DATE(v.data_venda), v.filial_id, p.departamento_%s_id
      ON CONFLICT (data, filial_id, departamento_nivel, departamento_id)
      DO UPDATE SET
        valor_total = EXCLUDED.valor_total,
        quantidade_vendas = EXCLUDED.quantidade_vendas,
        updated_at = NOW()
    ', p_schema, v_nivel, v_nivel, p_schema, p_schema, v_nivel, v_nivel)
    USING p_data_inicio, p_data_fim;
  END LOOP;

  GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

  RETURN json_build_object('success', true, 'rows_processed', v_rows_inserted);
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.atualizar_vendas_produto_mes(p_schema_name text, p_data_inicial text, p_data_final text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    mes_inicio DATE;
    mes_fim DATE;
    filial_rec RECORD;
    total_inserido INT := 0;
BEGIN
    SET LOCAL statement_timeout = '900s';
    SET LOCAL work_mem = '256MB';

    mes_inicio := date_trunc('month', p_data_inicial::DATE)::DATE;
    mes_fim := (date_trunc('month', p_data_final::DATE) + INTERVAL '1 month - 1 day')::DATE;

    RAISE NOTICE 'Processando periodo: % a %', mes_inicio, mes_fim;

    EXECUTE format('
        DELETE FROM %I.vendas_produto_mes
        WHERE mes_referencia >= %L AND mes_referencia <= %L
    ', p_schema_name, mes_inicio, mes_fim);

    FOR filial_rec IN
        EXECUTE format('
            SELECT DISTINCT filial_id
            FROM %I.vendas
            WHERE data_venda BETWEEN %L AND %L
            ORDER BY filial_id
        ', p_schema_name, mes_inicio, mes_fim)
    LOOP
        EXECUTE format('
            INSERT INTO %I.vendas_produto_mes (
                mes_referencia, filial_id, id_produto,
                quantidade_total, valor_total, ticket_medio,
                custo_total, lucro_total
            )
            SELECT
                date_trunc(''month'', v.data_venda)::date,
                v.filial_id,
                v.id_produto,
                SUM(v.quantidade),
                SUM(v.valor_vendas),
                SUM(v.valor_vendas) / NULLIF(SUM(v.quantidade), 0),
                SUM(v.quantidade * COALESCE(v.custo_compra, 0)),
                SUM(v.valor_vendas) - SUM(v.quantidade * COALESCE(v.custo_compra, 0))
            FROM %I.vendas v
            WHERE v.data_venda BETWEEN %L AND %L
              AND v.filial_id = %L
            GROUP BY date_trunc(''month'', v.data_venda), v.filial_id, v.id_produto
        ', p_schema_name, p_schema_name, mes_inicio, mes_fim, filial_rec.filial_id);

        GET DIAGNOSTICS total_inserido = ROW_COUNT;
        RAISE NOTICE 'Filial %: % registros inseridos', filial_rec.filial_id, total_inserido;
    END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.buscar_produtos_criticos(schema_name text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '300s'
AS $function$
DECLARE result_json JSON;
BEGIN
  EXECUTE format('
    SELECT COALESCE(json_agg(resultado), ''[]''::json)
    FROM (
      SELECT
        p.filial_id, d.descricao AS nome_departamento, p.id AS codigo_produto,
        p.descricao AS nome_produto, p.curva_abc, p.venda_media_diaria_60d, p.estoque_atual,
        p.dias_de_estoque, p.dias_com_venda_60d
      FROM
        %I.produtos AS p
      LEFT JOIN %I.departamentos AS d
        ON p.departamento_id = d.id AND p.departamento_nivel = d.nivel
      WHERE
        p.curva_abc = ''A'' AND p.estoque_atual > 0
        AND NOT EXISTS (
          SELECT 1 FROM %I.vendas AS v
          WHERE v.id_produto = p.id AND v.filial_id = p.filial_id
            AND v.data_venda >= (CURRENT_DATE - INTERVAL ''6 days'')
        )
      ORDER BY p.filial_id, d.descricao, p.descricao
    ) AS resultado;
  ', schema_name, schema_name, schema_name) INTO result_json;
  RETURN result_json;
END;
$function$;

CREATE OR REPLACE FUNCTION public.buscar_produtos_desacelerados(schema_name text, p_data_alvo text)
 RETURNS TABLE(filial_id bigint, segmento text, codigo_produto bigint, nome_produto text, estoque_atual numeric, dias_com_venda_60d bigint, dias_de_estoque numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    SET LOCAL statement_timeout = '600s';

    EXECUTE format('
        CREATE TEMP TABLE sales_metrics_temp AS
        SELECT
            v.filial_id,
            v.id_produto,
            COUNT(DISTINCT v.data_venda) AS dias_com_venda,
            SUM(v.quantidade) / 60.0 AS media_diaria_vendas
        FROM
            %I.vendas v
        WHERE
            v.data_venda BETWEEN (%L::DATE - INTERVAL ''59 days'') AND %L::DATE
        GROUP BY
            v.filial_id,
            v.id_produto
        HAVING
            COUNT(DISTINCT v.data_venda) >= 50;
    ', schema_name, p_data_alvo, p_data_alvo);

    CREATE INDEX ON sales_metrics_temp (id_produto, filial_id);

    RETURN QUERY EXECUTE format('
        WITH vendas_no_dia_alvo AS (
            SELECT DISTINCT v.filial_id, v.id_produto
            FROM %I.vendas v
            WHERE v.data_venda = %L::DATE
        )
        SELECT
            p.filial_id,
            COALESCE(d.description, ''Sem Segmento'') AS segmento,
            p.id AS codigo_produto,
            p.descricao AS nome_produto,
            p.estoque_atual,
            sm.dias_com_venda::BIGINT AS dias_com_venda_60d,
            CASE
                WHEN COALESCE(p.estoque_atual, 0) > 0 AND sm.media_diaria_vendas > 0 THEN
                    p.estoque_atual / sm.media_diaria_vendas
                ELSE 0
            END AS dias_de_estoque
        FROM
            %I.produtos p
        LEFT JOIN
            %I.departments d ON p.departamento_id = d.id
        JOIN
            sales_metrics_temp sm ON p.id = sm.id_produto AND p.filial_id = sm.filial_id
        LEFT JOIN
            vendas_no_dia_alvo vda ON p.id = vda.id_produto AND p.filial_id = vda.filial_id
        WHERE
            p.curva_abc IN (''A'', ''B'')
            AND p.ativo = TRUE
            AND vda.id_produto IS NULL;
    ', schema_name, p_data_alvo, schema_name, schema_name);
END;
$function$;

CREATE OR REPLACE FUNCTION public.buscar_produtos_ruptura_curva_a(schema_name text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '600s'
AS $function$
DECLARE result_json JSON;
BEGIN
  EXECUTE format('
    SELECT COALESCE(json_agg(resultado), ''[]''::json)
    FROM (
      SELECT
        p_ruptura.filial_id, d.descricao AS nome_departamento, p_ruptura.id AS codigo_produto,
        p_ruptura.descricao AS nome_produto, p_ruptura.curva_abc, p_ruptura.venda_media_diaria_60d, p_ruptura.estoque_atual,
        p_ruptura.dias_de_estoque, p_ruptura.dias_com_venda_60d,
        fonte.filial_sugerida, fonte.estoque_sugerido, fonte.dias_estoque_sugerido
      FROM
        %I.produtos AS p_ruptura
      LEFT JOIN %I.departamentos AS d
        ON p_ruptura.departamento_id = d.id AND p_ruptura.departamento_nivel = d.nivel
      LEFT JOIN LATERAL (
        SELECT f.filial_id AS filial_sugerida, f.estoque_atual AS estoque_sugerido, f.dias_de_estoque AS dias_estoque_sugerido
        FROM %I.produtos AS f
        WHERE f.id = p_ruptura.id AND f.filial_id != p_ruptura.filial_id
          AND f.estoque_atual > 0 AND f.dias_de_estoque > 5
        ORDER BY f.dias_de_estoque DESC LIMIT 1
      ) AS fonte ON true
      WHERE
        p_ruptura.curva_abc = ''A'' AND (p_ruptura.estoque_atual IS NULL OR p_ruptura.estoque_atual <= 0)
      ORDER BY
        p_ruptura.filial_id, d.descricao, p_ruptura.descricao
    ) AS resultado;
  ', schema_name, schema_name, schema_name) INTO result_json;
  RETURN result_json;
END;
$function$;

CREATE OR REPLACE FUNCTION public.buscar_resumo_vendas_curva(p_schema_name text, p_data_alvo text, p_filial_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(filial_id bigint, segmento text, codigo_produto bigint, nome_produto text, quantidade_vendida numeric, valor_vendido numeric, curva text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '300s'
AS $function$
DECLARE
    data_inicio DATE;
    data_fim DATE;
BEGIN
    data_inicio := to_date(p_data_alvo, 'YYYY-MM');
    data_fim := (data_inicio + INTERVAL '1 month - 1 day')::DATE;

    RETURN QUERY EXECUTE format('
        WITH depto_nivel_5 AS MATERIALIZED (
            SELECT DISTINCT ON (d1.id)
                d1.id,
                COALESCE(d5.descricao, d4.descricao, d3.descricao, d2.descricao, d1.descricao) as nome_segmento
            FROM %I.departamentos d1
            LEFT JOIN %I.departamentos d2 ON d1.parent_id = d2.id
            LEFT JOIN %I.departamentos d3 ON d2.parent_id = d3.id
            LEFT JOIN %I.departamentos d4 ON d3.parent_id = d4.id
            LEFT JOIN %I.departamentos d5 ON d4.parent_id = d5.id
        ),
        vendas_mensais AS (
            SELECT
                v.filial_id,
                v.id_produto,
                SUM(v.quantidade) AS total_quantidade,
                SUM(v.valor_vendas) AS total_valor
            FROM %I.vendas v
            WHERE v.data_venda BETWEEN %L AND %L
              AND (%L IS NULL OR v.filial_id = %L)
            GROUP BY v.filial_id, v.id_produto
        )
        SELECT DISTINCT ON (vm.filial_id, p.id)
            vm.filial_id,
            dn5.nome_segmento AS segmento,
            p.id AS codigo_produto,
            p.descricao AS nome_produto,
            vm.total_quantidade AS quantidade_vendida,
            vm.total_valor AS valor_vendido,
            p.curva_abc::TEXT AS curva
        FROM vendas_mensais vm
        JOIN %I.produtos p ON vm.id_produto = p.id
        LEFT JOIN depto_nivel_5 dn5 ON p.departamento_id = dn5.id
        ORDER BY vm.filial_id, p.id, vm.total_valor DESC;
    ',
    p_schema_name, p_schema_name, p_schema_name, p_schema_name, p_schema_name,
    p_schema_name,
    data_inicio, data_fim,
    p_filial_id, p_filial_id,
    p_schema_name
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.calcular_venda_media_diaria_60d(schema_name text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  start_time timestamptz := clock_timestamp();
  v_dias_periodo integer;
  v_rows_updated integer;
BEGIN
  SET statement_timeout = '120s';

  v_dias_periodo := (
    (date_trunc('month', CURRENT_DATE) - INTERVAL '1 day')::date
    -
    (date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')::date
    + 1
  )::integer;

  RAISE NOTICE 'Calculando venda media diaria para schema % com periodo de % dias', schema_name, v_dias_periodo;

  EXECUTE format('
    UPDATE %I.produtos AS p
    SET
      venda_media_diaria_60d = mv.total_quantidade_produto / $1::numeric
    FROM
      %I.vendas_agregadas_60d AS mv
    WHERE
      p.id = mv.id_produto
      AND p.filial_id = mv.filial_id;
  ', schema_name, schema_name)
  USING v_dias_periodo;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  PERFORM public.log_job(
      'calcular_venda_media_diaria_60d',
      schema_name,
      'SUCCESS',
      format('Calculo de QUANTIDADE media diaria (2 meses fechados = %s dias) concluido. %s produtos atualizados.', v_dias_periodo, v_rows_updated),
      start_time
  );

  RETURN format('Calculo concluido para %s: %s produtos atualizados (periodo: %s dias)', schema_name, v_rows_updated, v_dias_periodo);

EXCEPTION
  WHEN OTHERS THEN
    PERFORM public.log_job(
      'calcular_venda_media_diaria_60d',
      schema_name,
      'ERROR',
      SQLERRM,
      start_time
    );
    RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.carga_inicial_departamentos(data_json jsonb, schema_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    EXECUTE format('
        INSERT INTO %I.departments (id, source_level, description, parent_source_id, parent_source_level)
        SELECT
            (d->>''id'')::integer, (d->>''source_level'')::integer, d->>''description'',
            (d->>''parent_source_id'')::integer, (d->>''parent_source_level'')::integer
        FROM jsonb_array_elements(%L) AS d
        ON CONFLICT (id) DO UPDATE SET
            source_level = EXCLUDED.source_level, description = EXCLUDED.description,
            parent_source_id = EXCLUDED.parent_source_id, parent_source_level = EXCLUDED.parent_source_level,
            parent_id = NULL;
    ', schema_name, data_json);
END;
$function$;

CREATE OR REPLACE FUNCTION public.clone_schema_for_tenant(p_target_schema text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_source_schema TEXT := 'okilao';
    v_tables_created INT := 0;
    v_indexes_created INT := 0;
    v_pks_created INT := 0;
    v_unique_created INT := 0;
    v_fks_created INT := 0;
    v_mvs_created INT := 0;
    v_functions_created INT := 0;
    v_triggers_created INT := 0;
    r RECORD;
    v_pk_columns TEXT;
    v_unique_columns TEXT;
    v_new_constraint_name TEXT;
    v_new_indexname TEXT;
    v_new_indexdef TEXT;
    v_new_definition TEXT;
    v_func_def TEXT;
    v_trigger_sql TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = p_target_schema) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schema ja existe: ' || p_target_schema || '. Nao e possivel sobrescrever schemas existentes.'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = v_source_schema) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schema de origem nao encontrado: ' || v_source_schema
        );
    END IF;

    IF p_target_schema !~ '^[a-z][a-z0-9_]*$' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Nome do schema invalido. Use apenas letras minusculas, numeros e underscore, comecando com letra.'
        );
    END IF;

    EXECUTE format('CREATE SCHEMA %I', p_target_schema);

    FOR r IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = v_source_schema
          AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        BEGIN
            EXECUTE format(
                'CREATE TABLE %I.%I AS SELECT * FROM %I.%I WHERE 1=0',
                p_target_schema, r.table_name, v_source_schema, r.table_name
            );
            v_tables_created := v_tables_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Erro ao criar tabela %: %', r.table_name, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT DISTINCT tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        WHERE tc.table_schema = v_source_schema
          AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY tc.table_name
    LOOP
        SELECT string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position)
        INTO v_pk_columns
        FROM information_schema.key_column_usage kcu
        WHERE kcu.constraint_name = r.constraint_name
          AND kcu.table_schema = v_source_schema;

        BEGIN
            EXECUTE format(
                'ALTER TABLE %I.%I ADD PRIMARY KEY (%s)',
                p_target_schema, r.table_name, v_pk_columns
            );
            v_pks_created := v_pks_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'PK erro em %: %', r.table_name, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT DISTINCT tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        WHERE tc.table_schema = v_source_schema
          AND tc.constraint_type = 'UNIQUE'
        ORDER BY tc.table_name
    LOOP
        SELECT string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position)
        INTO v_unique_columns
        FROM information_schema.key_column_usage kcu
        WHERE kcu.constraint_name = r.constraint_name
          AND kcu.table_schema = v_source_schema;

        v_new_constraint_name := REPLACE(r.constraint_name, v_source_schema, p_target_schema);

        BEGIN
            EXECUTE format(
                'ALTER TABLE %I.%I ADD CONSTRAINT %I UNIQUE (%s)',
                p_target_schema, r.table_name, v_new_constraint_name, v_unique_columns
            );
            v_unique_created := v_unique_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'UNIQUE erro em %: %', r.table_name, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE schemaname = v_source_schema
          AND indexname NOT LIKE '%_pkey'
        ORDER BY tablename, indexname
    LOOP
        v_new_indexname := REPLACE(r.indexname, v_source_schema, p_target_schema);
        v_new_indexdef := REPLACE(r.indexdef, v_source_schema || '.', p_target_schema || '.');
        v_new_indexdef := REPLACE(v_new_indexdef, 'INDEX ' || r.indexname, 'INDEX ' || v_new_indexname);

        BEGIN
            EXECUTE v_new_indexdef;
            v_indexes_created := v_indexes_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Indice erro em %: %', v_new_indexname, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT
            tc.table_name,
            tc.constraint_name,
            kcu.column_name AS fk_column,
            ccu.table_name AS ref_table,
            ccu.column_name AS ref_column
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.table_schema = v_source_schema
            AND tc.constraint_type = 'FOREIGN KEY'
            AND (SELECT COUNT(*) FROM information_schema.key_column_usage k
                 WHERE k.constraint_name = tc.constraint_name
                   AND k.table_schema = tc.table_schema) = 1
        ORDER BY tc.table_name
    LOOP
        v_new_constraint_name := REPLACE(r.constraint_name, v_source_schema, p_target_schema);

        BEGIN
            EXECUTE format(
                'ALTER TABLE %I.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I.%I(%I)',
                p_target_schema, r.table_name, v_new_constraint_name,
                r.fk_column, p_target_schema, r.ref_table, r.ref_column
            );
            v_fks_created := v_fks_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'FK erro em %: %', r.table_name, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT matviewname, definition
        FROM pg_matviews
        WHERE schemaname = v_source_schema
        ORDER BY matviewname
    LOOP
        v_new_definition := REPLACE(r.definition, v_source_schema || '.', p_target_schema || '.');

        BEGIN
            EXECUTE format(
                'CREATE MATERIALIZED VIEW %I.%I AS %s',
                p_target_schema, r.matviewname, v_new_definition
            );
            v_mvs_created := v_mvs_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'MV erro em %: %', r.matviewname, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT p.oid, p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = v_source_schema
        ORDER BY p.proname
    LOOP
        v_func_def := pg_get_functiondef(r.oid);
        v_func_def := REPLACE(v_func_def, v_source_schema || '.', p_target_schema || '.');
        v_func_def := REPLACE(v_func_def, 'CREATE FUNCTION', 'CREATE OR REPLACE FUNCTION');

        BEGIN
            EXECUTE v_func_def;
            v_functions_created := v_functions_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Function erro em %: %', r.proname, SQLERRM;
        END;
    END LOOP;

    FOR r IN
        SELECT trigger_name, event_manipulation, event_object_table,
               action_timing, action_orientation, action_statement
        FROM information_schema.triggers
        WHERE trigger_schema = v_source_schema
        ORDER BY event_object_table, trigger_name
    LOOP
        v_trigger_sql := format(
            'CREATE TRIGGER %I %s %s ON %I.%I FOR EACH %s %s',
            r.trigger_name,
            r.action_timing,
            r.event_manipulation,
            p_target_schema,
            r.event_object_table,
            r.action_orientation,
            REPLACE(r.action_statement, v_source_schema || '.', p_target_schema || '.')
        );

        BEGIN
            EXECUTE v_trigger_sql;
            v_triggers_created := v_triggers_created + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Trigger erro em %: %', r.trigger_name, SQLERRM;
        END;
    END LOOP;

    EXECUTE format('GRANT USAGE ON SCHEMA %I TO anon, authenticated, service_role', p_target_schema);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO anon, authenticated, service_role', p_target_schema);
    EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO authenticated, service_role', p_target_schema);
    EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO anon, authenticated, service_role', p_target_schema);
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO authenticated, service_role', p_target_schema);

    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO anon, authenticated, service_role', p_target_schema);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO authenticated, service_role', p_target_schema);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT USAGE, SELECT ON SEQUENCES TO anon, authenticated, service_role', p_target_schema);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO authenticated, service_role', p_target_schema);

    BEGIN
        EXECUTE format('INSERT INTO %I.departments_level_6 SELECT * FROM %I.departments_level_6 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.departments_level_5 SELECT * FROM %I.departments_level_5 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.departments_level_4 SELECT * FROM %I.departments_level_4 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.departments_level_3 SELECT * FROM %I.departments_level_3 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.departments_level_2 SELECT * FROM %I.departments_level_2 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.departments_level_1 SELECT * FROM %I.departments_level_1 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.departamentos_nivel1 SELECT * FROM %I.departamentos_nivel1 ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.tipos_despesa SELECT * FROM %I.tipos_despesa ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
        EXECUTE format('INSERT INTO %I.motivos_perda SELECT * FROM %I.motivos_perda ON CONFLICT DO NOTHING', p_target_schema, v_source_schema);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Erro ao copiar dados de referencia: %', SQLERRM;
    END;

    FOR r IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = p_target_schema
          AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('ANALYZE %I.%I', p_target_schema, r.table_name);
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'schema', p_target_schema,
        'tables_created', v_tables_created,
        'indexes_created', v_indexes_created,
        'primary_keys_created', v_pks_created,
        'unique_constraints_created', v_unique_created,
        'foreign_keys_created', v_fks_created,
        'materialized_views_created', v_mvs_created,
        'functions_created', v_functions_created,
        'triggers_created', v_triggers_created
    );

EXCEPTION WHEN OTHERS THEN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = p_target_schema) THEN
        EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', p_target_schema);
        RAISE NOTICE 'Schema % removido devido a erro', p_target_schema;
    END IF;

    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.consultar_vendas_diarias(schema_name text, data_filtro date)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  result_json JSON;
BEGIN
  EXECUTE format('
    SELECT json_agg(t)
    FROM (
      SELECT * FROM %I.vendas_diarias_por_filial WHERE data_venda = $1
    ) t
  ', schema_name)
  INTO result_json
  USING data_filtro;

  RETURN COALESCE(result_json, '[]');
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_descontos_venda_table(schema_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I.descontos_venda (
      id uuid NOT NULL DEFAULT gen_random_uuid(),
      filial_id integer NOT NULL,
      data_desconto date NOT NULL,
      valor_desconto numeric(10, 2) NOT NULL,
      observacao text NULL,
      created_at timestamp with time zone NULL DEFAULT now(),
      updated_at timestamp with time zone NULL DEFAULT now(),
      created_by uuid NULL,
      CONSTRAINT descontos_venda_pkey PRIMARY KEY (id),
      CONSTRAINT descontos_venda_filial_id_data_desconto_key UNIQUE (filial_id, data_desconto),
      CONSTRAINT descontos_venda_valor_desconto_check CHECK (valor_desconto >= 0)
    )
  ', schema_name);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_descontos_venda_filial
    ON %I.descontos_venda USING btree (filial_id)
  ', schema_name);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_descontos_venda_data
    ON %I.descontos_venda USING btree (data_desconto)
  ', schema_name);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_descontos_venda_filial_data
    ON %I.descontos_venda USING btree (filial_id, data_desconto)
  ', schema_name);

  EXECUTE format('
    CREATE TRIGGER on_descontos_venda_update
    BEFORE UPDATE ON %I.descontos_venda
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at()
  ', schema_name);

  RAISE NOTICE 'Tabela descontos_venda criada no schema %', schema_name;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_metas_table_for_tenant(schema_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS %I.metas_mensais (
      id bigserial PRIMARY KEY,
      filial_id bigint NOT NULL,
      data date NOT NULL,
      dia_semana text NOT NULL,
      meta_percentual numeric(5, 2) NOT NULL DEFAULT 0,
      data_referencia date NOT NULL,
      valor_referencia numeric(15, 2) DEFAULT 0,
      valor_meta numeric(15, 2) DEFAULT 0,
      valor_realizado numeric(15, 2) DEFAULT 0,
      diferenca numeric(15, 2) DEFAULT 0,
      diferenca_percentual numeric(5, 2) DEFAULT 0,
      situacao text DEFAULT ''pendente'',
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now(),
      CONSTRAINT metas_mensais_unique_filial_data UNIQUE (filial_id, data)
    );

    CREATE INDEX IF NOT EXISTS idx_metas_mensais_filial_data
      ON %I.metas_mensais(filial_id, data);

    CREATE INDEX IF NOT EXISTS idx_metas_mensais_data
      ON %I.metas_mensais(data);

    CREATE TRIGGER on_metas_mensais_update
      BEFORE UPDATE ON %I.metas_mensais
      FOR EACH ROW
      EXECUTE FUNCTION handle_updated_at();
  ', schema_name, schema_name, schema_name, schema_name);
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_venda_curva_indexes(p_schema text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  RAISE NOTICE 'Creating indexes for schema: %', p_schema;

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_vendas_data_filial_valor
    ON %I.vendas (data_venda, filial_id)
    WHERE valor_vendas > 0
  ', p_schema);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_vendas_produto_filial
    ON %I.vendas (id_produto, filial_id)
  ', p_schema);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_produtos_ativo_dept
    ON %I.produtos (departamento_id, ativo, curva_abcd)
    WHERE ativo = true
  ', p_schema);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_dept1_pais
    ON %I.departments_level_1 (pai_level_2_id, pai_level_3_id)
  ', p_schema);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_dept2_departamento
    ON %I.departments_level_2 (departamento_id)
  ', p_schema);

  EXECUTE format('
    CREATE INDEX IF NOT EXISTS idx_dept3_departamento
    ON %I.departments_level_3 (departamento_id)
  ', p_schema);

  EXECUTE format('ANALYZE %I.vendas', p_schema);
  EXECUTE format('ANALYZE %I.produtos', p_schema);
  EXECUTE format('ANALYZE %I.departments_level_1', p_schema);
  EXECUTE format('ANALYZE %I.departments_level_2', p_schema);
  EXECUTE format('ANALYZE %I.departments_level_3', p_schema);

  RAISE NOTICE 'Indexes created and statistics updated for schema: %', p_schema;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_desconto_venda(p_schema text, p_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_affected integer;
BEGIN
  EXECUTE format(
    'DELETE FROM %I.descontos_venda WHERE id = $1',
    p_schema
  ) USING p_id;

  GET DIAGNOSTICS v_affected = ROW_COUNT;

  RETURN v_affected > 0;
END;
$function$;

CREATE OR REPLACE FUNCTION public.drop_mview(p_schema_name text, p_view_name text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF p_view_name IS NULL OR p_view_name = '' THEN
        RAISE EXCEPTION 'O nome da view nao pode ser nulo ou vazio.';
    END IF;

    EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I.%I;', p_schema_name, p_view_name);

    RETURN 'View ' || p_schema_name || '.' || p_view_name || ' removida com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Erro ao tentar remover a view ' || p_schema_name || '.' || p_view_name || '. Detalhes: ' || SQLERRM;
END;
$function$;

CREATE OR REPLACE FUNCTION public.enrich_level_1_hierarchy(schema_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  EXECUTE format('
    UPDATE
      %I.departments_level_1 AS l1
    SET
      pai_level_3_id = L3.departamento_id,
      pai_level_4_id = L4.departamento_id,
      pai_level_5_id = L5.departamento_id,
      pai_level_6_id = L6.departamento_id
    FROM
      %I.departments_level_2 AS L2
      LEFT JOIN %I.departments_level_3 AS L3 ON L2.pai_level_3_id = L3.departamento_id
      LEFT JOIN %I.departments_level_4 AS L4 ON L3.pai_level_4_id = L4.departamento_id
      LEFT JOIN %I.departments_level_5 AS L5 ON L4.pai_level_5_id = L5.departamento_id
      LEFT JOIN %I.departments_level_6 AS L6 ON L5.pai_level_6_id = L6.departamento_id
    WHERE
      l1.pai_level_2_id = L2.departamento_id;
  ',
  schema_name,
  schema_name,
  schema_name,
  schema_name,
  schema_name,
  schema_name
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.ensure_superadmin_can_switch()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.role = 'superadmin' THEN
    NEW.can_switch_tenants = true;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.executar_sincronizacao_com_logs(tenant_id text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_erro TEXT;
    categoria INT;
BEGIN
    BEGIN
        PERFORM public.refresh_vendas_agregadas_30d(tenant_id);
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'refresh_vendas_agregadas_30d', 'SUCESSO', 'OK');
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'refresh_vendas_agregadas_30d', 'ERRO', v_erro);
    END;

    BEGIN
        PERFORM public.calcular_venda_media_diaria_60d(tenant_id);
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'calcular_venda_media_diaria_60d', 'SUCESSO', 'OK');
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'calcular_venda_media_diaria_60d', 'ERRO', v_erro);
    END;

    BEGIN
        PERFORM public.atualizar_dias_com_venda_60d(tenant_id);
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'atualizar_dias_com_venda_60d', 'SUCESSO', 'OK');
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'atualizar_dias_com_venda_60d', 'ERRO', v_erro);
    END;

    BEGIN
        PERFORM public.atualizar_dias_de_estoque(tenant_id);
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'atualizar_dias_de_estoque', 'SUCESSO', 'OK');
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'atualizar_dias_de_estoque', 'ERRO', v_erro);
    END;

    FOREACH categoria IN ARRAY ARRAY[1, 4, 6, 7, 9] LOOP
        BEGIN
            PERFORM public.atualizar_curva_abcd_30d(tenant_id, ARRAY[categoria]);
            INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
            VALUES (tenant_id, format('atualizar_curva_abcd_30d[%s]', categoria), 'SUCESSO', 'OK');
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
            INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
            VALUES (tenant_id, format('atualizar_curva_abcd_30d[%s]', categoria), 'ERRO', v_erro);
        END;
    END LOOP;

    FOREACH categoria IN ARRAY ARRAY[1, 4, 6, 7, 9] LOOP
        BEGIN
            PERFORM public.atualizar_curva_lucro(tenant_id, ARRAY[categoria]);
            INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
            VALUES (tenant_id, format('atualizar_curva_lucro[%s]', categoria), 'SUCESSO', 'OK');
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
            INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
            VALUES (tenant_id, format('atualizar_curva_lucro[%s]', categoria), 'ERRO', v_erro);
        END;
    END LOOP;

    BEGIN
        PERFORM public.refresh_report_curva_abcd(tenant_id);
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'refresh_report_curva_abcd', 'SUCESSO', 'OK');
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        INSERT INTO logs_sincronizacao (tenant_id, etapa, status, mensagem)
        VALUES (tenant_id, 'refresh_report_curva_abcd', 'ERRO', v_erro);
    END;

END;
$function$;

CREATE OR REPLACE FUNCTION public.executar_sincronizacao_completa(tenant_id text)
 RETURNS TABLE(etapa text, status text, mensagem text, executado_em timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_inicio TIMESTAMP;
    v_erro TEXT;
    categoria INT;
BEGIN
    v_inicio := NOW();

    BEGIN
        PERFORM public.refresh_vendas_agregadas_30d(tenant_id);
        RETURN QUERY SELECT
            'refresh_vendas_agregadas_30d'::TEXT,
            'SUCESSO'::TEXT,
            'Executado com sucesso'::TEXT,
            NOW()::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        RETURN QUERY SELECT
            'refresh_vendas_agregadas_30d'::TEXT,
            'ERRO'::TEXT,
            v_erro::TEXT,
            NOW()::TIMESTAMP;
        RAISE NOTICE 'Erro em refresh_vendas_agregadas_30d: %', v_erro;
    END;

    BEGIN
        PERFORM public.calcular_venda_media_diaria_60d(tenant_id);
        RETURN QUERY SELECT
            'calcular_venda_media_diaria_60d'::TEXT,
            'SUCESSO'::TEXT,
            'Executado com sucesso'::TEXT,
            NOW()::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        RETURN QUERY SELECT
            'calcular_venda_media_diaria_60d'::TEXT,
            'ERRO'::TEXT,
            v_erro::TEXT,
            NOW()::TIMESTAMP;
    END;

    BEGIN
        PERFORM public.atualizar_dias_com_venda_60d(tenant_id);
        RETURN QUERY SELECT
            'atualizar_dias_com_venda_60d'::TEXT,
            'SUCESSO'::TEXT,
            'Executado com sucesso'::TEXT,
            NOW()::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        RETURN QUERY SELECT
            'atualizar_dias_com_venda_60d'::TEXT,
            'ERRO'::TEXT,
            v_erro::TEXT,
            NOW()::TIMESTAMP;
    END;

    BEGIN
        PERFORM public.atualizar_dias_de_estoque(tenant_id);
        RETURN QUERY SELECT
            'atualizar_dias_de_estoque'::TEXT,
            'SUCESSO'::TEXT,
            'Executado com sucesso'::TEXT,
            NOW()::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        RETURN QUERY SELECT
            'atualizar_dias_de_estoque'::TEXT,
            'ERRO'::TEXT,
            v_erro::TEXT,
            NOW()::TIMESTAMP;
    END;

    FOREACH categoria IN ARRAY ARRAY[1, 4, 6, 7, 9] LOOP
        BEGIN
            PERFORM public.atualizar_curva_abcd_30d(tenant_id, ARRAY[categoria]);
            RETURN QUERY SELECT
                format('atualizar_curva_abcd_30d[%s]', categoria)::TEXT,
                'SUCESSO'::TEXT,
                'Executado com sucesso'::TEXT,
                NOW()::TIMESTAMP;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
            RETURN QUERY SELECT
                format('atualizar_curva_abcd_30d[%s]', categoria)::TEXT,
                'ERRO'::TEXT,
                v_erro::TEXT,
                NOW()::TIMESTAMP;
        END;
    END LOOP;

    FOREACH categoria IN ARRAY ARRAY[1, 4, 6, 7, 9] LOOP
        BEGIN
            PERFORM public.atualizar_curva_lucro(tenant_id, ARRAY[categoria]);
            RETURN QUERY SELECT
                format('atualizar_curva_lucro[%s]', categoria)::TEXT,
                'SUCESSO'::TEXT,
                'Executado com sucesso'::TEXT,
                NOW()::TIMESTAMP;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
            RETURN QUERY SELECT
                format('atualizar_curva_lucro[%s]', categoria)::TEXT,
                'ERRO'::TEXT,
                v_erro::TEXT,
                NOW()::TIMESTAMP;
        END;
    END LOOP;

    BEGIN
        PERFORM public.refresh_report_curva_abcd(tenant_id);
        RETURN QUERY SELECT
            'refresh_report_curva_abcd'::TEXT,
            'SUCESSO'::TEXT,
            'Executado com sucesso'::TEXT,
            NOW()::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_erro = MESSAGE_TEXT;
        RETURN QUERY SELECT
            'refresh_report_curva_abcd'::TEXT,
            'ERRO'::TEXT,
            v_erro::TEXT,
            NOW()::TIMESTAMP;
    END;

END;
$function$;

CREATE OR REPLACE FUNCTION public.expand_departamento_hierarchy(p_schema text, p_nivel5_ids bigint[])
 RETURNS bigint[]
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_all_ids BIGINT[];
BEGIN
  EXECUTE format('
    SELECT ARRAY_AGG(DISTINCT dept_id)
    FROM (
      SELECT unnest($1::bigint[]) as dept_id

      UNION

      SELECT d4.departamento_id
      FROM %I.departments_level_4 d4
      WHERE d4.pai_level_5_id = ANY($1)

      UNION

      SELECT d3.departamento_id
      FROM %I.departments_level_3 d3
      INNER JOIN %I.departments_level_4 d4 ON d3.pai_level_4_id = d4.departamento_id
      WHERE d4.pai_level_5_id = ANY($1)

      UNION

      SELECT d2.departamento_id
      FROM %I.departments_level_2 d2
      INNER JOIN %I.departments_level_3 d3 ON d2.pai_level_3_id = d3.departamento_id
      INNER JOIN %I.departments_level_4 d4 ON d3.pai_level_4_id = d4.departamento_id
      WHERE d4.pai_level_5_id = ANY($1)

      UNION

      SELECT d1.departamento_id
      FROM %I.departments_level_1 d1
      INNER JOIN %I.departments_level_2 d2 ON d1.pai_level_2_id = d2.departamento_id
      INNER JOIN %I.departments_level_3 d3 ON d2.pai_level_3_id = d3.departamento_id
      INNER JOIN %I.departments_level_4 d4 ON d3.pai_level_4_id = d4.departamento_id
      WHERE d4.pai_level_5_id = ANY($1)
    ) all_depts
  ', p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema, p_schema)
  INTO v_all_ids
  USING p_nivel5_ids;

  RETURN COALESCE(v_all_ids, ARRAY[]::bigint[]);
END;
$function$;

CREATE OR REPLACE FUNCTION public.finalizar_carga_produtos(p_filial_id integer)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    batch_size INTEGER := 10000;
    offset_val INTEGER := 0;
    rows_processed INTEGER;
    total_rows_processed INTEGER := 0;
    staging_ids BIGINT[];
BEGIN
    SET LOCAL statement_timeout = '600s';

    CREATE TEMP TABLE temp_hierarquia_map ON COMMIT DROP AS
    WITH RECURSIVE department_paths AS (
        SELECT id AS original_id, id, parent_id, nivel FROM paraiso.departamentos
        UNION ALL
        SELECT p.original_id, d.id, d.parent_id, d.nivel FROM paraiso.departamentos d
        JOIN department_paths p ON p.parent_id = d.id
    )
    SELECT
        original_id,
        MAX(CASE WHEN nivel = 1 THEN id END) as dep_nivel_1_id,
        MAX(CASE WHEN nivel = 2 THEN id END) as dep_nivel_2_id,
        MAX(CASE WHEN nivel = 3 THEN id END) as dep_nivel_3_id,
        MAX(CASE WHEN nivel = 4 THEN id END) as dep_nivel_4_id,
        MAX(CASE WHEN nivel = 5 THEN id END) as dep_nivel_5_id,
        MAX(CASE WHEN nivel = 6 THEN id END) as dep_nivel_6_id
    FROM department_paths
    GROUP BY original_id;

    CREATE INDEX ON temp_hierarquia_map(original_id);

    LOOP
        SELECT ARRAY(
            SELECT id FROM paraiso.staging_produtos
            WHERE filial_id = p_filial_id
            ORDER BY id
            LIMIT batch_size OFFSET offset_val
        ) INTO staging_ids;

        IF array_length(staging_ids, 1) IS NULL THEN
            EXIT;
        END IF;

        INSERT INTO paraiso.produtos (
            id, filial_id, descricao, ativo, balanca, unidade_de_medida, curva_abc, ultimo_fornecedor,
            preco_de_venda_1, preco_de_venda_2, preco_de_custo, custo_real, custo_fiscal, custo_com_encargos,
            custo_medio, estoque_atual, qtde_por_embalagem_ultima_entrada, data_cadastro, data_alteracao_preco,
            data_alteracao_custo, data_alteracao_cadastro, marca_id, classe_id, agrupamento_id, departamento_id,
            dep_nivel_1_id, dep_nivel_2_id, dep_nivel_3_id, dep_nivel_4_id, dep_nivel_5_id, dep_nivel_6_id
        )
        SELECT
            s.id, s.filial_id, s.descricao, s.ativo, s.balanca, s.unidade_de_medida, s.curva_abc, s.ultimo_fornecedor,
            s.preco_de_venda_1, s.preco_de_venda_2, s.preco_de_custo, s.custo_real, s.custo_fiscal, s.custo_com_encargos,
            s.custo_medio, s.estoque_atual, s.qtde_por_embalagem_ultima_entrada, s.data_cadastro, s.data_alteracao_preco,
            s.data_alteracao_custo, s.data_alteracao_cadastro, s.marca_id, s.classe_id, s.agrupamento_id, s.departamento_id,
            h.dep_nivel_1_id, h.dep_nivel_2_id, h.dep_nivel_3_id, h.dep_nivel_4_id, h.dep_nivel_5_id, h.dep_nivel_6_id
        FROM paraiso.staging_produtos s
        LEFT JOIN temp_hierarquia_map h ON s.departamento_id = h.original_id
        WHERE s.id = ANY(staging_ids)
        ON CONFLICT (id, filial_id) DO UPDATE SET
            descricao = EXCLUDED.descricao, ativo = EXCLUDED.ativo, balanca = EXCLUDED.balanca, unidade_de_medida = EXCLUDED.unidade_de_medida,
            curva_abc = EXCLUDED.curva_abc, ultimo_fornecedor = EXCLUDED.ultimo_fornecedor, preco_de_venda_1 = EXCLUDED.preco_de_venda_1,
            preco_de_venda_2 = EXCLUDED.preco_de_venda_2, preco_de_custo = EXCLUDED.preco_de_custo, custo_real = EXCLUDED.custo_real,
            custo_fiscal = EXCLUDED.custo_fiscal, custo_com_encargos = EXCLUDED.custo_com_encargos, custo_medio = EXCLUDED.custo_medio,
            estoque_atual = EXCLUDED.estoque_atual, qtde_por_embalagem_ultima_entrada = EXCLUDED.qtde_por_embalagem_ultima_entrada,
            data_cadastro = EXCLUDED.data_cadastro, data_alteracao_preco = EXCLUDED.data_alteracao_preco,
            data_alteracao_custo = EXCLUDED.data_alteracao_custo, data_alteracao_cadastro = EXCLUDED.data_alteracao_cadastro,
            marca_id = EXCLUDED.marca_id, classe_id = EXCLUDED.classe_id, agrupamento_id = EXCLUDED.agrupamento_id,
            departamento_id = EXCLUDED.departamento_id, dep_nivel_1_id = EXCLUDED.dep_nivel_1_id,
            dep_nivel_2_id = EXCLUDED.dep_nivel_2_id, dep_nivel_3_id = EXCLUDED.dep_nivel_3_id,
            dep_nivel_4_id = EXCLUDED.dep_nivel_4_id, dep_nivel_5_id = EXCLUDED.dep_nivel_5_id,
            dep_nivel_6_id = EXCLUDED.dep_nivel_6_id, updated_at = NOW();

        GET DIAGNOSTICS rows_processed = ROW_COUNT;
        total_rows_processed := total_rows_processed + rows_processed;

        offset_val := offset_val + batch_size;
    END LOOP;

    RETURN 'Processados ' || total_rows_processed || ' produtos em lotes.';
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_metas_mensais(p_schema text, p_filial_id bigint, p_mes integer, p_ano integer, p_meta_percentual numeric, p_data_referencia_inicial date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_data_meta date;
  v_data_referencia date;
  v_dia_semana text;
  v_valor_referencia numeric(15, 2);
  v_desconto_referencia numeric(15, 2);
  v_valor_meta numeric(15, 2);
  v_valor_realizado numeric(15, 2);
  v_desconto_realizado numeric(15, 2);
  v_diferenca numeric(15, 2);
  v_diferenca_percentual numeric(5, 2);
  v_records_created integer := 0;
  v_first_day date;
  v_last_day date;
BEGIN
  v_first_day := make_date(p_ano, p_mes, 1);
  v_last_day := (v_first_day + interval '1 month' - interval '1 day')::date;

  EXECUTE format('
    DELETE FROM %I.metas_mensais
    WHERE filial_id = $1
      AND EXTRACT(YEAR FROM data) = $2
      AND EXTRACT(MONTH FROM data) = $3
  ', p_schema)
  USING p_filial_id, p_ano, p_mes;

  v_data_referencia := p_data_referencia_inicial;

  FOR v_data_meta IN
    SELECT generate_series(v_first_day, v_last_day, '1 day'::interval)::date
  LOOP
    v_dia_semana := CASE EXTRACT(DOW FROM v_data_meta)
      WHEN 0 THEN 'Domingo'
      WHEN 1 THEN 'Segunda-Feira'
      WHEN 2 THEN 'Terca-Feira'
      WHEN 3 THEN 'Quarta-Feira'
      WHEN 4 THEN 'Quinta-Feira'
      WHEN 5 THEN 'Sexta-Feira'
      WHEN 6 THEN 'Sabado'
    END;

    EXECUTE format('
      SELECT COALESCE(valor_total, 0)
      FROM %I.vendas_diarias_por_filial
      WHERE filial_id = $1 AND data_venda = $2
    ', p_schema)
    INTO v_valor_referencia
    USING p_filial_id, v_data_referencia;

    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE filial_id = $1 AND data_desconto = $2
    ', p_schema)
    INTO v_desconto_referencia
    USING p_filial_id, v_data_referencia;

    v_valor_referencia := v_valor_referencia - v_desconto_referencia;

    v_valor_meta := v_valor_referencia * (1 + (p_meta_percentual / 100));

    EXECUTE format('
      SELECT COALESCE(valor_total, 0)
      FROM %I.vendas_diarias_por_filial
      WHERE filial_id = $1 AND data_venda = $2
    ', p_schema)
    INTO v_valor_realizado
    USING p_filial_id, v_data_meta;

    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE filial_id = $1 AND data_desconto = $2
    ', p_schema)
    INTO v_desconto_realizado
    USING p_filial_id, v_data_meta;

    v_valor_realizado := v_valor_realizado - v_desconto_realizado;

    v_diferenca := v_valor_realizado - v_valor_meta;

    IF v_valor_meta > 0 THEN
      v_diferenca_percentual := (v_diferenca / v_valor_meta) * 100;
    ELSE
      v_diferenca_percentual := 0;
    END IF;

    EXECUTE format('
      INSERT INTO %I.metas_mensais (
        filial_id, data, dia_semana, meta_percentual,
        data_referencia, valor_referencia, valor_meta,
        valor_realizado, diferenca, diferenca_percentual
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    ', p_schema)
    USING
      p_filial_id, v_data_meta, v_dia_semana, p_meta_percentual,
      v_data_referencia, v_valor_referencia, v_valor_meta,
      v_valor_realizado, v_diferenca, v_diferenca_percentual;

    v_records_created := v_records_created + 1;

    v_data_referencia := v_data_referencia + interval '1 day';
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'records_created', v_records_created,
    'filial_id', p_filial_id,
    'mes', p_mes,
    'ano', p_ano
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_metas_setor(p_schema text, p_setor_id bigint, p_mes integer, p_ano integer, p_filial_ids bigint[] DEFAULT NULL::bigint[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET statement_timeout TO '30s'
 SET work_mem TO '64MB'
AS $function$
DECLARE
  v_result JSONB;
  v_date_start DATE;
  v_date_end DATE;
  v_rows_inserted INT;
  v_existing_rows INT;
  v_query_start TIMESTAMP;
  v_query_duration INTERVAL;
BEGIN
  v_query_start := clock_timestamp();

  IF p_schema IS NULL OR p_setor_id IS NULL OR p_mes IS NULL OR p_ano IS NULL THEN
    RAISE EXCEPTION 'Schema, setor_id, mes e ano sao obrigatorios';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mes invalido: % (deve ser 1-12)', p_mes;
  END IF;

  v_date_start := make_date(p_ano, p_mes, 1);
  v_date_end := v_date_start + INTERVAL '1 month' - INTERVAL '1 day';

  EXECUTE format('
    SELECT EXISTS(
      SELECT 1 FROM %I.setores
      WHERE id = $1 AND ativo = true
    )
  ', p_schema)
  INTO v_result
  USING p_setor_id;

  IF NOT (v_result::text::boolean) THEN
    RAISE EXCEPTION 'Setor % nao encontrado ou inativo', p_setor_id;
  END IF;

  EXECUTE format('
    SELECT COUNT(*)
    FROM %I.metas_setor
    WHERE setor_id = $1
      AND data >= $2
      AND data <= $3
      AND ($4::bigint[] IS NULL OR filial_id = ANY($4))
  ', p_schema)
  INTO v_existing_rows
  USING p_setor_id, v_date_start, v_date_end, p_filial_ids;

  IF v_existing_rows > 0 THEN
    EXECUTE format('
      DELETE FROM %I.metas_setor
      WHERE setor_id = $1
        AND data >= $2
        AND data <= $3
        AND ($4::bigint[] IS NULL OR filial_id = ANY($4))
    ', p_schema)
    USING p_setor_id, v_date_start, v_date_end, p_filial_ids;
  END IF;

  EXECUTE format('
    INSERT INTO %I.metas_setor (
      setor_id,
      filial_id,
      data,
      valor_meta,
      valor_realizado,
      diferenca,
      diferenca_percentual,
      created_at,
      updated_at
    )
    SELECT
      $1,
      f.id,
      d.dia::DATE,
      0,
      0,
      0,
      0,
      NOW(),
      NOW()
    FROM %I.filiais f
    CROSS JOIN generate_series(
      $2::DATE,
      $3::DATE,
      INTERVAL ''1 day''
    ) AS d(dia)
    WHERE ($4::bigint[] IS NULL OR f.id = ANY($4))
      AND f.ativo = true
    ORDER BY f.id, d.dia
  ', p_schema, p_schema)
  USING p_setor_id, v_date_start, v_date_end, p_filial_ids;

  GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

  v_query_duration := clock_timestamp() - v_query_start;

  RETURN jsonb_build_object(
    'success', true,
    'rows_inserted', v_rows_inserted,
    'rows_deleted', v_existing_rows,
    'setor_id', p_setor_id,
    'mes', p_mes,
    'ano', p_ano,
    'filial_ids', COALESCE(p_filial_ids, ARRAY[]::bigint[]),
    'duration_ms', EXTRACT(EPOCH FROM v_query_duration) * 1000,
    'message', format('%s metas geradas com sucesso', v_rows_inserted)
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', true,
      'message', SQLERRM,
      'detail', SQLSTATE,
      'setor_id', p_setor_id
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_metas_setor(
  p_schema text,
  p_setor_id bigint,
  p_filial_id bigint,
  p_mes integer,
  p_ano integer,
  p_meta_percentual numeric,
  p_data_referencia_inicial date
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_setor RECORD;
  v_dias_no_mes INT;
  v_current_date DATE;
  v_data_referencia DATE;
  v_dia_semana TEXT;
  v_dia_semana_ref TEXT;
  v_valor_referencia NUMERIC;
  v_valor_meta NUMERIC;
  v_valor_realizado NUMERIC;
  v_diferenca NUMERIC;
  v_diferenca_percentual NUMERIC;
  v_rows_inserted INT := 0;
  v_dept_ids_level_1 BIGINT[];
BEGIN
  EXECUTE format(
    'SELECT departamento_nivel, departamento_ids FROM %I.setores WHERE id = $1 AND (ativo IS NULL OR ativo = true)',
    p_schema
  ) INTO v_setor USING p_setor_id;

  IF v_setor.departamento_ids IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Setor não encontrado');
  END IF;

  v_dept_ids_level_1 := public.get_departamentos_hierarquia_simples(
    p_schema,
    v_setor.departamento_nivel,
    v_setor.departamento_ids
  );

  IF v_dept_ids_level_1 IS NULL OR array_length(v_dept_ids_level_1, 1) IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Nenhum departamento encontrado na hierarquia');
  END IF;

  v_dias_no_mes := EXTRACT(DAY FROM (DATE_TRUNC('month', MAKE_DATE(p_ano, p_mes, 1)) + INTERVAL '1 month' - INTERVAL '1 day'));

  EXECUTE format(
    'DELETE FROM %I.metas_setor WHERE setor_id = $1 AND filial_id = $2 AND EXTRACT(MONTH FROM data) = $3 AND EXTRACT(YEAR FROM data) = $4',
    p_schema
  ) USING p_setor_id, p_filial_id, p_mes, p_ano;

  FOR i IN 1..v_dias_no_mes LOOP
    v_current_date := MAKE_DATE(p_ano, p_mes, i);
    v_data_referencia := p_data_referencia_inicial + (i - 1);

    v_dia_semana := CASE EXTRACT(DOW FROM v_current_date)
      WHEN 0 THEN 'Domingo'
      WHEN 1 THEN 'Segunda-Feira'
      WHEN 2 THEN 'Terça-Feira'
      WHEN 3 THEN 'Quarta-Feira'
      WHEN 4 THEN 'Quinta-Feira'
      WHEN 5 THEN 'Sexta-Feira'
      WHEN 6 THEN 'Sábado'
    END;

    v_dia_semana_ref := CASE EXTRACT(DOW FROM v_data_referencia)
      WHEN 0 THEN 'Domingo'
      WHEN 1 THEN 'Segunda-Feira'
      WHEN 2 THEN 'Terça-Feira'
      WHEN 3 THEN 'Quarta-Feira'
      WHEN 4 THEN 'Quinta-Feira'
      WHEN 5 THEN 'Sexta-Feira'
      WHEN 6 THEN 'Sábado'
    END;

    EXECUTE format('
      SELECT COALESCE(SUM(v.valor_vendas), 0)
      FROM %I.vendas v
      JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
      WHERE v.filial_id = $1
        AND v.data_venda = $2
        AND p.departamento_id = ANY($3)
    ', p_schema, p_schema)
    INTO v_valor_referencia
    USING p_filial_id, v_data_referencia, v_dept_ids_level_1;

    v_valor_meta := CASE WHEN v_valor_referencia > 0 THEN v_valor_referencia * (1 + (p_meta_percentual / 100)) ELSE NULL END;

    EXECUTE format('
      SELECT COALESCE(SUM(v.valor_vendas), 0)
      FROM %I.vendas v
      JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
      WHERE v.filial_id = $1
        AND v.data_venda = $2
        AND p.departamento_id = ANY($3)
    ', p_schema, p_schema)
    INTO v_valor_realizado
    USING p_filial_id, v_current_date, v_dept_ids_level_1;

    v_diferenca := CASE WHEN v_valor_meta IS NOT NULL THEN v_valor_realizado - v_valor_meta ELSE NULL END;
    v_diferenca_percentual := CASE WHEN v_valor_meta > 0 THEN (v_diferenca / v_valor_meta) * 100 ELSE 0 END;

    EXECUTE format(
      'INSERT INTO %I.metas_setor (setor_id, filial_id, data, dia_semana, meta_percentual, data_referencia, dia_semana_ref, valor_referencia, valor_meta, valor_realizado, diferenca, diferenca_percentual)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)',
      p_schema
    )
    USING p_setor_id, p_filial_id, v_current_date, v_dia_semana, p_meta_percentual, v_data_referencia, v_dia_semana_ref, v_valor_referencia, v_valor_meta, v_valor_realizado, v_diferenca, v_diferenca_percentual;

    v_rows_inserted := v_rows_inserted + 1;
  END LOOP;

  RETURN json_build_object(
    'success', true,
    'rows_inserted', v_rows_inserted,
    'message', format('Metas geradas: %s linhas', v_rows_inserted),
    'debug', json_build_object(
      'nivel', v_setor.departamento_nivel,
      'dept_ids_config', v_setor.departamento_ids,
      'dept_ids_level_1', v_dept_ids_level_1
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_metas_setores(
  p_schema text,
  p_setor_id bigint,
  p_filial_id bigint,
  p_mes integer,
  p_ano integer,
  p_meta_percentual numeric,
  p_data_referencia_inicial date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result jsonb;
  v_dias_no_mes integer;
  v_data_atual date;
  v_data_referencia date;
  v_dia_semana text;
  v_valor_referencia numeric;
  v_valor_meta numeric;
  v_valor_realizado numeric;
  v_diferenca numeric;
  v_diferenca_percentual numeric;
  v_departamento_ids bigint[];
  v_departamento_nivel smallint;
  v_count integer := 0;
BEGIN
  EXECUTE format('
    SELECT departamento_ids, departamento_nivel
    FROM %I.setores
    WHERE id = $1 AND ativo = true
  ', p_schema)
  INTO v_departamento_ids, v_departamento_nivel
  USING p_setor_id;

  IF v_departamento_ids IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Setor não encontrado ou inativo');
  END IF;

  v_dias_no_mes := EXTRACT(DAY FROM (DATE_TRUNC('month', make_date(p_ano, p_mes, 1)) + INTERVAL '1 month' - INTERVAL '1 day'));

  EXECUTE format('
    DELETE FROM %I.metas_setores
    WHERE setor_id = $1 
      AND filial_id = $2
      AND EXTRACT(MONTH FROM data) = $3
      AND EXTRACT(YEAR FROM data) = $4
  ', p_schema)
  USING p_setor_id, p_filial_id, p_mes, p_ano;

  FOR i IN 1..v_dias_no_mes LOOP
    v_data_atual := make_date(p_ano, p_mes, i);
    v_data_referencia := p_data_referencia_inicial + (i - 1);

    v_dia_semana := CASE EXTRACT(DOW FROM v_data_atual)
      WHEN 0 THEN 'Domingo'
      WHEN 1 THEN 'Segunda-Feira'
      WHEN 2 THEN 'Terça-Feira'
      WHEN 3 THEN 'Quarta-Feira'
      WHEN 4 THEN 'Quinta-Feira'
      WHEN 5 THEN 'Sexta-Feira'
      WHEN 6 THEN 'Sábado'
    END;

    EXECUTE format('
      SELECT COALESCE(SUM(v.valor_vendas), 0)
      FROM %I.vendas v
      INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
      WHERE v.filial_id = $1
        AND v.data_venda = $2
        AND p.departamento_id = ANY($3)
        AND p.departamento_nivel = $4
    ', p_schema, p_schema)
    INTO v_valor_referencia
    USING p_filial_id, v_data_referencia, v_departamento_ids, v_departamento_nivel;

    IF v_valor_referencia > 0 THEN
      v_valor_meta := v_valor_referencia * (1 + p_meta_percentual / 100);
    ELSE
      v_valor_meta := NULL;
    END IF;

    EXECUTE format('
      SELECT COALESCE(SUM(v.valor_vendas), 0)
      FROM %I.vendas v
      INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
      WHERE v.filial_id = $1
        AND v.data_venda = $2
        AND p.departamento_id = ANY($3)
        AND p.departamento_nivel = $4
    ', p_schema, p_schema)
    INTO v_valor_realizado
    USING p_filial_id, v_data_atual, v_departamento_ids, v_departamento_nivel;

    IF v_valor_meta IS NOT NULL AND v_valor_realizado IS NOT NULL THEN
      v_diferenca := v_valor_realizado - v_valor_meta;
      IF v_valor_meta > 0 THEN
        v_diferenca_percentual := (v_diferenca / v_valor_meta) * 100;
      ELSE
        v_diferenca_percentual := 0;
      END IF;
    ELSE
      v_diferenca := NULL;
      v_diferenca_percentual := NULL;
    END IF;

    EXECUTE format('
      INSERT INTO %I.metas_setores (
        setor_id, filial_id, data, dia_semana, meta_percentual,
        data_referencia, valor_referencia, valor_meta,
        valor_realizado, diferenca, diferenca_percentual
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      ON CONFLICT (setor_id, filial_id, data) 
      DO UPDATE SET
        dia_semana = EXCLUDED.dia_semana,
        meta_percentual = EXCLUDED.meta_percentual,
        data_referencia = EXCLUDED.data_referencia,
        valor_referencia = EXCLUDED.valor_referencia,
        valor_meta = EXCLUDED.valor_meta,
        valor_realizado = EXCLUDED.valor_realizado,
        diferenca = EXCLUDED.diferenca,
        diferenca_percentual = EXCLUDED.diferenca_percentual,
        updated_at = now()
    ', p_schema)
    USING p_setor_id, p_filial_id, v_data_atual, v_dia_semana, p_meta_percentual,
          v_data_referencia, v_valor_referencia, v_valor_meta,
          v_valor_realizado, v_diferenca, v_diferenca_percentual;

    v_count := v_count + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'metas_geradas', v_count,
    'mes', p_mes,
    'ano', p_ano,
    'setor_id', p_setor_id,
    'filial_id', p_filial_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_accessible_tenants(user_id uuid)
RETURNS SETOF tenants
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  IF is_superadmin(user_id) THEN
    RETURN QUERY
    SELECT t.* FROM tenants t
    WHERE t.is_active = true
    ORDER BY t.name;
  ELSE
    RETURN QUERY
    SELECT t.* FROM tenants t
    INNER JOIN user_profiles up ON up.tenant_id = t.id
    WHERE up.id = user_id
      AND t.is_active = true;
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_data(
  schema_name text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids text[] DEFAULT NULL::text[]
)
RETURNS TABLE(
  total_vendas numeric,
  total_lucro numeric,
  ticket_medio numeric,
  margem_lucro numeric,
  pa_vendas numeric,
  pa_lucro numeric,
  pa_ticket_medio numeric,
  pa_margem_lucro numeric,
  variacao_vendas_mes numeric,
  variacao_lucro_mes numeric,
  variacao_ticket_mes numeric,
  variacao_margem_mes numeric,
  variacao_vendas_ano numeric,
  variacao_lucro_ano numeric,
  variacao_ticket_ano numeric,
  variacao_margem_ano numeric,
  ytd_vendas numeric,
  ytd_vendas_ano_anterior numeric,
  ytd_variacao_percent numeric,
  grafico_vendas json,
  reserved text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_total_vendas NUMERIC := 0;
  v_total_lucro NUMERIC := 0;
  v_total_transacoes NUMERIC := 0;
  v_ticket_medio NUMERIC := 0;
  v_margem_lucro NUMERIC := 0;

  v_pa_vendas NUMERIC := 0;
  v_pa_lucro NUMERIC := 0;
  v_pa_transacoes NUMERIC := 0;
  v_pa_ticket_medio NUMERIC := 0;
  v_pa_margem_lucro NUMERIC := 0;

  v_paa_vendas NUMERIC := 0;
  v_paa_lucro NUMERIC := 0;
  v_paa_transacoes NUMERIC := 0;
  v_paa_ticket_medio NUMERIC := 0;
  v_paa_margem_lucro NUMERIC := 0;

  v_ytd_vendas NUMERIC := 0;
  v_ytd_vendas_ano_anterior NUMERIC := 0;
  v_ytd_variacao_percent NUMERIC := 0;

  v_variacao_vendas_mes NUMERIC := 0;
  v_variacao_lucro_mes NUMERIC := 0;
  v_variacao_ticket_mes NUMERIC := 0;
  v_variacao_margem_mes NUMERIC := 0;

  v_variacao_vendas_ano NUMERIC := 0;
  v_variacao_lucro_ano NUMERIC := 0;
  v_variacao_ticket_ano NUMERIC := 0;
  v_variacao_margem_ano NUMERIC := 0;

  v_grafico_vendas JSON := '[]'::JSON;

  v_data_inicio_pa DATE;
  v_data_fim_pa DATE;
  v_data_inicio_paa DATE;
  v_data_fim_paa DATE;
  v_data_inicio_ytd DATE;
  v_data_fim_ytd DATE;
  v_data_inicio_ytd_ano_anterior DATE;
  v_data_fim_ytd_ano_anterior DATE;

  v_descontos_periodo NUMERIC := 0;
  v_descontos_pa NUMERIC := 0;
  v_descontos_paa NUMERIC := 0;
  v_descontos_ytd NUMERIC := 0;
  v_descontos_ytd_ano_anterior NUMERIC := 0;

  v_table_exists BOOLEAN;
BEGIN
  v_data_inicio_pa := (p_data_inicio - INTERVAL '1 month')::DATE;
  v_data_fim_pa := (p_data_fim - INTERVAL '1 month')::DATE;

  v_data_inicio_paa := (p_data_inicio - INTERVAL '1 year')::DATE;
  v_data_fim_paa := (p_data_fim - INTERVAL '1 year')::DATE;

  v_data_inicio_ytd := DATE_TRUNC('year', p_data_inicio)::DATE;
  v_data_fim_ytd := p_data_fim;
  v_data_inicio_ytd_ano_anterior := (v_data_inicio_ytd - INTERVAL '1 year')::DATE;
  v_data_fim_ytd_ano_anterior := (v_data_fim_ytd - INTERVAL '1 year')::DATE;

  -- Check if descontos_venda table exists
  EXECUTE format('
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = %L AND table_name = ''descontos_venda''
    )', schema_name) INTO v_table_exists;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0),
      COALESCE(SUM(total_lucro), 0),
      COALESCE(SUM(total_transacoes), 0)
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING p_data_inicio, p_data_fim, p_filiais_ids
  INTO v_total_vendas, v_total_lucro, v_total_transacoes;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING p_data_inicio, p_data_fim, p_filiais_ids
    INTO v_descontos_periodo;

    v_total_vendas := v_total_vendas - v_descontos_periodo;
    v_total_lucro := v_total_lucro - v_descontos_periodo;
  END IF;

  IF v_total_transacoes > 0 THEN
    v_ticket_medio := v_total_vendas / v_total_transacoes;
  END IF;

  IF v_total_vendas > 0 THEN
    v_margem_lucro := (v_total_lucro / v_total_vendas) * 100;
  END IF;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0),
      COALESCE(SUM(total_lucro), 0),
      COALESCE(SUM(total_transacoes), 0)
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_pa, v_data_fim_pa, p_filiais_ids
  INTO v_pa_vendas, v_pa_lucro, v_pa_transacoes;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_pa, v_data_fim_pa, p_filiais_ids
    INTO v_descontos_pa;

    v_pa_vendas := v_pa_vendas - v_descontos_pa;
    v_pa_lucro := v_pa_lucro - v_descontos_pa;
  END IF;

  IF v_pa_transacoes > 0 THEN
    v_pa_ticket_medio := v_pa_vendas / v_pa_transacoes;
  END IF;

  IF v_pa_vendas > 0 THEN
    v_pa_margem_lucro := (v_pa_lucro / v_pa_vendas) * 100;
  END IF;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0),
      COALESCE(SUM(total_lucro), 0),
      COALESCE(SUM(total_transacoes), 0)
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_paa, v_data_fim_paa, p_filiais_ids
  INTO v_paa_vendas, v_paa_lucro, v_paa_transacoes;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_paa, v_data_fim_paa, p_filiais_ids
    INTO v_descontos_paa;

    v_paa_vendas := v_paa_vendas - v_descontos_paa;
    v_paa_lucro := v_paa_lucro - v_descontos_paa;
  END IF;

  IF v_paa_transacoes > 0 THEN
    v_paa_ticket_medio := v_paa_vendas / v_paa_transacoes;
  END IF;

  IF v_paa_vendas > 0 THEN
    v_paa_margem_lucro := (v_paa_lucro / v_paa_vendas) * 100;
  END IF;

  IF v_pa_vendas > 0 THEN
    v_variacao_vendas_mes := ((v_total_vendas - v_pa_vendas) / v_pa_vendas) * 100;
  END IF;

  IF v_pa_lucro > 0 THEN
    v_variacao_lucro_mes := ((v_total_lucro - v_pa_lucro) / v_pa_lucro) * 100;
  END IF;

  IF v_pa_ticket_medio > 0 THEN
    v_variacao_ticket_mes := ((v_ticket_medio - v_pa_ticket_medio) / v_pa_ticket_medio) * 100;
  END IF;

  v_variacao_margem_mes := v_margem_lucro - v_pa_margem_lucro;

  IF v_paa_vendas > 0 THEN
    v_variacao_vendas_ano := ((v_total_vendas - v_paa_vendas) / v_paa_vendas) * 100;
  END IF;

  IF v_paa_lucro > 0 THEN
    v_variacao_lucro_ano := ((v_total_lucro - v_paa_lucro) / v_paa_lucro) * 100;
  END IF;

  IF v_paa_ticket_medio > 0 THEN
    v_variacao_ticket_ano := ((v_ticket_medio - v_paa_ticket_medio) / v_paa_ticket_medio) * 100;
  END IF;

  v_variacao_margem_ano := v_margem_lucro - v_paa_margem_lucro;

  EXECUTE format('
    SELECT COALESCE(SUM(valor_total), 0)
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_ytd, v_data_fim_ytd, p_filiais_ids
  INTO v_ytd_vendas;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_ytd, v_data_fim_ytd, p_filiais_ids
    INTO v_descontos_ytd;

    v_ytd_vendas := v_ytd_vendas - v_descontos_ytd;
  END IF;

  EXECUTE format('
    SELECT COALESCE(SUM(valor_total), 0)
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_ytd_ano_anterior, v_data_fim_ytd_ano_anterior, p_filiais_ids
  INTO v_ytd_vendas_ano_anterior;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_ytd_ano_anterior, v_data_fim_ytd_ano_anterior, p_filiais_ids
    INTO v_descontos_ytd_ano_anterior;

    v_ytd_vendas_ano_anterior := v_ytd_vendas_ano_anterior - v_descontos_ytd_ano_anterior;
  END IF;

  IF v_ytd_vendas_ano_anterior > 0 THEN
    v_ytd_variacao_percent := ((v_ytd_vendas - v_ytd_vendas_ano_anterior) / v_ytd_vendas_ano_anterior) * 100;
  END IF;

  EXECUTE format('
    SELECT COALESCE(
      json_agg(
        json_build_object(
          ''mes'', TO_CHAR(data_venda, ''DD/MM''),
          ''ano_atual'', vendas_atual,
          ''ano_anterior'', vendas_anterior
        ) ORDER BY data_venda
      ),
      ''[]''::JSON
    )
    FROM (
      SELECT
        v1.data_venda,
        COALESCE(SUM(v1.valor_total), 0) as vendas_atual,
        COALESCE(SUM(v2.valor_total), 0) as vendas_anterior
      FROM %I.vendas_diarias_por_filial v1
      LEFT JOIN %I.vendas_diarias_por_filial v2
        ON v2.data_venda = (v1.data_venda - INTERVAL ''1 year'')::DATE
        AND ($3 IS NULL OR v2.filial_id = ANY($3::INTEGER[]))
      WHERE v1.data_venda BETWEEN $1 AND $2
        AND ($3 IS NULL OR v1.filial_id = ANY($3::INTEGER[]))
      GROUP BY v1.data_venda
    ) dados
  ', schema_name, schema_name)
  USING p_data_inicio, p_data_fim, p_filiais_ids
  INTO v_grafico_vendas;

  RETURN QUERY SELECT
    v_total_vendas,
    v_total_lucro,
    v_ticket_medio,
    v_margem_lucro,
    v_pa_vendas,
    v_pa_lucro,
    v_pa_ticket_medio,
    v_pa_margem_lucro,
    v_variacao_vendas_mes,
    v_variacao_lucro_mes,
    v_variacao_ticket_mes,
    v_variacao_margem_mes,
    v_variacao_vendas_ano,
    v_variacao_lucro_ano,
    v_variacao_ticket_ano,
    v_variacao_margem_ano,
    v_ytd_vendas,
    v_ytd_vendas_ano_anterior,
    v_ytd_variacao_percent,
    v_grafico_vendas,
    NULL::TEXT;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_data_test(
  schema_name text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids text[] DEFAULT NULL::text[]
)
RETURNS TABLE(
  total_vendas numeric,
  total_lucro numeric,
  ticket_medio numeric,
  margem_lucro numeric,
  pa_vendas numeric,
  pa_lucro numeric,
  pa_ticket_medio numeric,
  pa_margem_lucro numeric,
  variacao_vendas_mes numeric,
  variacao_lucro_mes numeric,
  variacao_ticket_mes numeric,
  variacao_margem_mes numeric,
  variacao_vendas_ano numeric,
  variacao_lucro_ano numeric,
  variacao_ticket_ano numeric,
  variacao_margem_ano numeric,
  ytd_vendas numeric,
  ytd_vendas_ano_anterior numeric,
  ytd_variacao_percent numeric,
  grafico_vendas jsonb
)
LANGUAGE plpgsql
STABLE
AS $function$
DECLARE
  periodo_dias INT := p_data_fim - p_data_inicio;
  data_inicio_mes_ant DATE := p_data_inicio - interval '1 month';
  data_fim_mes_ant DATE := data_inicio_mes_ant + periodo_dias;
  data_inicio_ano_ant DATE := p_data_inicio - interval '1 year';
  data_fim_ano_ant DATE := data_inicio_ano_ant + periodo_dias;

  data_inicio_ytd DATE := date_trunc('year', CURRENT_DATE)::DATE;
  data_fim_ytd DATE := CURRENT_DATE;
  data_inicio_ytd_ant DATE := date_trunc('year', CURRENT_DATE - interval '1 year')::DATE;
  data_fim_ytd_ant DATE := data_inicio_ytd_ant + (data_fim_ytd - data_inicio_ytd);

  v_vendas_atual NUMERIC; v_lucro_atual NUMERIC; v_transacoes_atual BIGINT;
  v_ticket_medio_atual NUMERIC; v_margem_lucro_atual NUMERIC;
  v_vendas_mes_ant NUMERIC; v_lucro_mes_ant NUMERIC; v_transacoes_mes_ant BIGINT;
  v_ticket_medio_mes_ant NUMERIC; v_margem_lucro_mes_ant NUMERIC;
  v_vendas_ano_ant NUMERIC; v_lucro_ano_ant NUMERIC; v_transacoes_ano_ant BIGINT;
  v_ticket_medio_ano_ant NUMERIC; v_margem_lucro_ano_ant NUMERIC;

  v_descontos_atual NUMERIC := 0;
  v_descontos_mes_ant NUMERIC := 0;
  v_descontos_ano_ant NUMERIC := 0;
  v_descontos_ytd NUMERIC := 0;
  v_descontos_ytd_ant NUMERIC := 0;

  v_ytd_vendas NUMERIC;
  v_ytd_vendas_ant NUMERIC;
  v_ytd_variacao NUMERIC;

  v_grafico_vendas JSONB;

  filter_clause TEXT;
BEGIN
  IF p_filiais_ids IS NOT NULL AND array_length(p_filiais_ids, 1) > 0 THEN
    filter_clause := format('AND filial_id::TEXT = ANY(%L)', p_filiais_ids);
  ELSE
    filter_clause := '';
  END IF;

  EXECUTE format('SELECT COALESCE(SUM(valor_total),0), COALESCE(SUM(total_lucro),0), COALESCE(SUM(total_transacoes),0) FROM %I.vendas_diarias_por_filial WHERE data_venda BETWEEN %L AND %L %s', schema_name, p_data_inicio, p_data_fim, filter_clause) INTO v_vendas_atual, v_lucro_atual, v_transacoes_atual;
  EXECUTE format('SELECT COALESCE(SUM(valor_total),0), COALESCE(SUM(total_lucro),0), COALESCE(SUM(total_transacoes),0) FROM %I.vendas_diarias_por_filial WHERE data_venda BETWEEN %L AND %L %s', schema_name, data_inicio_mes_ant, data_fim_mes_ant, filter_clause) INTO v_vendas_mes_ant, v_lucro_mes_ant, v_transacoes_mes_ant;
  EXECUTE format('SELECT COALESCE(SUM(valor_total),0), COALESCE(SUM(total_lucro),0), COALESCE(SUM(total_transacoes),0) FROM %I.vendas_diarias_por_filial WHERE data_venda BETWEEN %L AND %L %s', schema_name, data_inicio_ano_ant, data_fim_ano_ant, filter_clause) INTO v_vendas_ano_ant, v_lucro_ano_ant, v_transacoes_ano_ant;

  EXECUTE format('SELECT COALESCE(SUM(valor_total),0) FROM %I.vendas_diarias_por_filial WHERE data_venda BETWEEN %L AND %L %s', schema_name, data_inicio_ytd, data_fim_ytd, filter_clause) INTO v_ytd_vendas;
  EXECUTE format('SELECT COALESCE(SUM(valor_total),0) FROM %I.vendas_diarias_por_filial WHERE data_venda BETWEEN %L AND %L %s', schema_name, data_inicio_ytd_ant, data_fim_ytd_ant, filter_clause) INTO v_ytd_vendas_ant;

  EXECUTE format('SELECT COALESCE(SUM(valor_desconto),0) FROM %I.descontos_venda WHERE data_desconto BETWEEN %L AND %L %s', schema_name, p_data_inicio, p_data_fim, filter_clause) INTO v_descontos_atual;
  EXECUTE format('SELECT COALESCE(SUM(valor_desconto),0) FROM %I.descontos_venda WHERE data_desconto BETWEEN %L AND %L %s', schema_name, data_inicio_mes_ant, data_fim_mes_ant, filter_clause) INTO v_descontos_mes_ant;
  EXECUTE format('SELECT COALESCE(SUM(valor_desconto),0) FROM %I.descontos_venda WHERE data_desconto BETWEEN %L AND %L %s', schema_name, data_inicio_ano_ant, data_fim_ano_ant, filter_clause) INTO v_descontos_ano_ant;
  EXECUTE format('SELECT COALESCE(SUM(valor_desconto),0) FROM %I.descontos_venda WHERE data_desconto BETWEEN %L AND %L %s', schema_name, data_inicio_ytd, data_fim_ytd, filter_clause) INTO v_descontos_ytd;
  EXECUTE format('SELECT COALESCE(SUM(valor_desconto),0) FROM %I.descontos_venda WHERE data_desconto BETWEEN %L AND %L %s', schema_name, data_inicio_ytd_ant, data_fim_ytd_ant, filter_clause) INTO v_descontos_ytd_ant;

  v_vendas_atual := v_vendas_atual - v_descontos_atual;
  v_lucro_atual := v_lucro_atual - v_descontos_atual;
  v_vendas_mes_ant := v_vendas_mes_ant - v_descontos_mes_ant;
  v_lucro_mes_ant := v_lucro_mes_ant - v_descontos_mes_ant;
  v_vendas_ano_ant := v_vendas_ano_ant - v_descontos_ano_ant;
  v_lucro_ano_ant := v_lucro_ano_ant - v_descontos_ano_ant;
  v_ytd_vendas := v_ytd_vendas - v_descontos_ytd;
  v_ytd_vendas_ant := v_ytd_vendas_ant - v_descontos_ytd_ant;

  v_ticket_medio_atual := CASE WHEN v_transacoes_atual > 0 THEN v_vendas_atual / v_transacoes_atual ELSE 0 END;
  v_margem_lucro_atual := CASE WHEN v_vendas_atual > 0 THEN (v_lucro_atual / v_vendas_atual) * 100 ELSE 0 END;
  v_ticket_medio_mes_ant := CASE WHEN v_transacoes_mes_ant > 0 THEN v_vendas_mes_ant / v_transacoes_mes_ant ELSE 0 END;
  v_margem_lucro_mes_ant := CASE WHEN v_vendas_mes_ant > 0 THEN (v_lucro_mes_ant / v_vendas_mes_ant) * 100 ELSE 0 END;
  v_ticket_medio_ano_ant := CASE WHEN v_transacoes_ano_ant > 0 THEN v_vendas_ano_ant / v_transacoes_ano_ant ELSE 0 END;
  v_margem_lucro_ano_ant := CASE WHEN v_vendas_ano_ant > 0 THEN (v_lucro_ano_ant / v_vendas_ano_ant) * 100 ELSE 0 END;

  v_ytd_variacao := CASE WHEN v_ytd_vendas_ant > 0 THEN ((v_ytd_vendas - v_ytd_vendas_ant) / v_ytd_vendas_ant) * 100 ELSE 0 END;

  total_vendas := v_vendas_atual;
  total_lucro := v_lucro_atual;
  ticket_medio := v_ticket_medio_atual;
  margem_lucro := v_margem_lucro_atual;

  pa_vendas := v_vendas_mes_ant;
  pa_lucro := v_lucro_mes_ant;
  pa_ticket_medio := v_ticket_medio_mes_ant;
  pa_margem_lucro := v_margem_lucro_mes_ant;

  variacao_vendas_mes := CASE WHEN v_vendas_mes_ant > 0 THEN ((v_vendas_atual - v_vendas_mes_ant) / v_vendas_mes_ant) * 100 ELSE 0 END;
  variacao_lucro_mes := CASE WHEN v_lucro_mes_ant > 0 THEN ((v_lucro_atual - v_lucro_mes_ant) / v_lucro_mes_ant) * 100 ELSE 0 END;
  variacao_ticket_mes := CASE WHEN v_ticket_medio_mes_ant > 0 THEN ((v_ticket_medio_atual - v_ticket_medio_mes_ant) / v_ticket_medio_mes_ant) * 100 ELSE 0 END;
  variacao_margem_mes := v_margem_lucro_atual - v_margem_lucro_mes_ant;
  variacao_vendas_ano := CASE WHEN v_vendas_ano_ant > 0 THEN ((v_vendas_atual - v_vendas_ano_ant) / v_vendas_ano_ant) * 100 ELSE 0 END;
  variacao_lucro_ano := CASE WHEN v_lucro_ano_ant > 0 THEN ((v_lucro_atual - v_lucro_ano_ant) / v_lucro_ano_ant) * 100 ELSE 0 END;
  variacao_ticket_ano := CASE WHEN v_ticket_medio_ano_ant > 0 THEN ((v_ticket_medio_atual - v_ticket_medio_ano_ant) / v_ticket_medio_ano_ant) * 100 ELSE 0 END;
  variacao_margem_ano := v_margem_lucro_atual - v_margem_lucro_ano_ant;

  ytd_vendas := v_ytd_vendas;
  ytd_vendas_ano_anterior := v_ytd_vendas_ant;
  ytd_variacao_percent := v_ytd_variacao;

  grafico_vendas := '[]'::jsonb;

  RETURN NEXT;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_mtd_metrics(
  schema_name text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids text[] DEFAULT NULL::text[]
)
RETURNS TABLE(
  mtd_vendas numeric,
  mtd_lucro numeric,
  mtd_margem numeric,
  mtd_mes_anterior_vendas numeric,
  mtd_mes_anterior_lucro numeric,
  mtd_mes_anterior_margem numeric,
  mtd_variacao_mes_anterior_vendas_percent numeric,
  mtd_variacao_mes_anterior_lucro_percent numeric,
  mtd_variacao_mes_anterior_margem numeric,
  mtd_ano_anterior_vendas numeric,
  mtd_ano_anterior_lucro numeric,
  mtd_ano_anterior_margem numeric,
  mtd_variacao_ano_anterior_vendas_percent numeric,
  mtd_variacao_ano_anterior_lucro_percent numeric,
  mtd_variacao_ano_anterior_margem numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_reference_day INTEGER;
  v_mtd_end_day INTEGER;
  v_is_full_past_month BOOLEAN;

  v_data_inicio_mtd DATE;
  v_data_fim_mtd DATE;
  v_data_inicio_mtd_mes_anterior DATE;
  v_data_fim_mtd_mes_anterior DATE;
  v_data_inicio_mtd_ano_anterior DATE;
  v_data_fim_mtd_ano_anterior DATE;

  v_mtd_vendas NUMERIC := 0;
  v_mtd_lucro NUMERIC := 0;
  v_mtd_margem NUMERIC := 0;

  v_mtd_mes_anterior_vendas NUMERIC := 0;
  v_mtd_mes_anterior_lucro NUMERIC := 0;
  v_mtd_mes_anterior_margem NUMERIC := 0;

  v_mtd_ano_anterior_vendas NUMERIC := 0;
  v_mtd_ano_anterior_lucro NUMERIC := 0;
  v_mtd_ano_anterior_margem NUMERIC := 0;

  v_mtd_variacao_mes_anterior_vendas_percent NUMERIC := 0;
  v_mtd_variacao_mes_anterior_lucro_percent NUMERIC := 0;
  v_mtd_variacao_mes_anterior_margem NUMERIC := 0;
  v_mtd_variacao_ano_anterior_vendas_percent NUMERIC := 0;
  v_mtd_variacao_ano_anterior_lucro_percent NUMERIC := 0;
  v_mtd_variacao_ano_anterior_margem NUMERIC := 0;

  v_descontos_mtd NUMERIC := 0;
  v_descontos_mtd_mes_anterior NUMERIC := 0;
  v_descontos_mtd_ano_anterior NUMERIC := 0;
  v_table_exists BOOLEAN;

  v_last_day_mes_anterior INTEGER;
  v_last_day_ano_anterior INTEGER;
  v_is_first_day_of_month BOOLEAN;
  v_last_day_of_filter_month INTEGER;
  v_is_last_day_of_month BOOLEAN;
  v_is_past_month BOOLEAN;
BEGIN
  v_is_first_day_of_month := EXTRACT(DAY FROM p_data_inicio) = 1;
  v_last_day_of_filter_month := EXTRACT(DAY FROM (DATE_TRUNC('month', p_data_inicio) + INTERVAL '1 month' - INTERVAL '1 day')::DATE);
  v_is_last_day_of_month := EXTRACT(DAY FROM p_data_fim) = v_last_day_of_filter_month;
  v_is_past_month := p_data_fim < CURRENT_DATE;
  v_is_full_past_month := v_is_first_day_of_month AND v_is_last_day_of_month AND v_is_past_month;

  IF p_data_fim >= CURRENT_DATE THEN
    v_reference_day := EXTRACT(DAY FROM CURRENT_DATE);
  ELSE
    v_reference_day := EXTRACT(DAY FROM p_data_fim);
  END IF;

  v_data_inicio_mtd := DATE_TRUNC('month', p_data_inicio)::DATE;
  v_data_fim_mtd := LEAST(
    (DATE_TRUNC('month', p_data_inicio) + (v_reference_day - 1) * INTERVAL '1 day')::DATE,
    p_data_fim
  );

  v_data_inicio_mtd_mes_anterior := (DATE_TRUNC('month', p_data_inicio) - INTERVAL '1 month')::DATE;
  v_last_day_mes_anterior := EXTRACT(DAY FROM (DATE_TRUNC('month', p_data_inicio) - INTERVAL '1 day')::DATE);

  IF v_is_full_past_month THEN
    v_data_fim_mtd_mes_anterior := (v_data_inicio_mtd_mes_anterior + (v_last_day_mes_anterior - 1) * INTERVAL '1 day')::DATE;
  ELSE
    v_mtd_end_day := LEAST(v_reference_day, v_last_day_mes_anterior);
    v_data_fim_mtd_mes_anterior := (v_data_inicio_mtd_mes_anterior + (v_mtd_end_day - 1) * INTERVAL '1 day')::DATE;
  END IF;

  v_data_inicio_mtd_ano_anterior := (DATE_TRUNC('month', p_data_inicio) - INTERVAL '1 year')::DATE;
  v_last_day_ano_anterior := EXTRACT(DAY FROM ((DATE_TRUNC('month', p_data_inicio) - INTERVAL '1 year') + INTERVAL '1 month' - INTERVAL '1 day')::DATE);

  IF v_is_full_past_month THEN
    v_data_fim_mtd_ano_anterior := (v_data_inicio_mtd_ano_anterior + (v_last_day_ano_anterior - 1) * INTERVAL '1 day')::DATE;
  ELSE
    v_mtd_end_day := LEAST(v_reference_day, v_last_day_ano_anterior);
    v_data_fim_mtd_ano_anterior := (v_data_inicio_mtd_ano_anterior + (v_mtd_end_day - 1) * INTERVAL '1 day')::DATE;
  END IF;

  EXECUTE format('
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = %L AND table_name = ''descontos_venda''
    )', schema_name) INTO v_table_exists;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0) as vendas,
      COALESCE(SUM(total_lucro), 0) as lucro
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_mtd, v_data_fim_mtd, p_filiais_ids
  INTO v_mtd_vendas, v_mtd_lucro;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_mtd, v_data_fim_mtd, p_filiais_ids
    INTO v_descontos_mtd;

    v_mtd_vendas := v_mtd_vendas - v_descontos_mtd;
    v_mtd_lucro := v_mtd_lucro - v_descontos_mtd;
  END IF;

  IF v_mtd_vendas > 0 THEN
    v_mtd_margem := (v_mtd_lucro / v_mtd_vendas) * 100;
  ELSE
    v_mtd_margem := 0;
  END IF;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0) as vendas,
      COALESCE(SUM(total_lucro), 0) as lucro
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_mtd_mes_anterior, v_data_fim_mtd_mes_anterior, p_filiais_ids
  INTO v_mtd_mes_anterior_vendas, v_mtd_mes_anterior_lucro;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_mtd_mes_anterior, v_data_fim_mtd_mes_anterior, p_filiais_ids
    INTO v_descontos_mtd_mes_anterior;

    v_mtd_mes_anterior_vendas := v_mtd_mes_anterior_vendas - v_descontos_mtd_mes_anterior;
    v_mtd_mes_anterior_lucro := v_mtd_mes_anterior_lucro - v_descontos_mtd_mes_anterior;
  END IF;

  IF v_mtd_mes_anterior_vendas > 0 THEN
    v_mtd_mes_anterior_margem := (v_mtd_mes_anterior_lucro / v_mtd_mes_anterior_vendas) * 100;
  ELSE
    v_mtd_mes_anterior_margem := 0;
  END IF;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0) as vendas,
      COALESCE(SUM(total_lucro), 0) as lucro
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_mtd_ano_anterior, v_data_fim_mtd_ano_anterior, p_filiais_ids
  INTO v_mtd_ano_anterior_vendas, v_mtd_ano_anterior_lucro;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_mtd_ano_anterior, v_data_fim_mtd_ano_anterior, p_filiais_ids
    INTO v_descontos_mtd_ano_anterior;

    v_mtd_ano_anterior_vendas := v_mtd_ano_anterior_vendas - v_descontos_mtd_ano_anterior;
    v_mtd_ano_anterior_lucro := v_mtd_ano_anterior_lucro - v_descontos_mtd_ano_anterior;
  END IF;

  IF v_mtd_ano_anterior_vendas > 0 THEN
    v_mtd_ano_anterior_margem := (v_mtd_ano_anterior_lucro / v_mtd_ano_anterior_vendas) * 100;
  ELSE
    v_mtd_ano_anterior_margem := 0;
  END IF;

  IF v_mtd_mes_anterior_vendas > 0 THEN
    v_mtd_variacao_mes_anterior_vendas_percent := ((v_mtd_vendas - v_mtd_mes_anterior_vendas) / v_mtd_mes_anterior_vendas) * 100;
  ELSE
    v_mtd_variacao_mes_anterior_vendas_percent := 0;
  END IF;

  IF v_mtd_mes_anterior_lucro > 0 THEN
    v_mtd_variacao_mes_anterior_lucro_percent := ((v_mtd_lucro - v_mtd_mes_anterior_lucro) / v_mtd_mes_anterior_lucro) * 100;
  ELSE
    v_mtd_variacao_mes_anterior_lucro_percent := 0;
  END IF;

  v_mtd_variacao_mes_anterior_margem := v_mtd_margem - v_mtd_mes_anterior_margem;

  IF v_mtd_ano_anterior_vendas > 0 THEN
    v_mtd_variacao_ano_anterior_vendas_percent := ((v_mtd_vendas - v_mtd_ano_anterior_vendas) / v_mtd_ano_anterior_vendas) * 100;
  ELSE
    v_mtd_variacao_ano_anterior_vendas_percent := 0;
  END IF;

  IF v_mtd_ano_anterior_lucro > 0 THEN
    v_mtd_variacao_ano_anterior_lucro_percent := ((v_mtd_lucro - v_mtd_ano_anterior_lucro) / v_mtd_ano_anterior_lucro) * 100;
  ELSE
    v_mtd_variacao_ano_anterior_lucro_percent := 0;
  END IF;

  v_mtd_variacao_ano_anterior_margem := v_mtd_margem - v_mtd_ano_anterior_margem;

  RETURN QUERY SELECT
    v_mtd_vendas,
    v_mtd_lucro,
    v_mtd_margem,
    v_mtd_mes_anterior_vendas,
    v_mtd_mes_anterior_lucro,
    v_mtd_mes_anterior_margem,
    v_mtd_variacao_mes_anterior_vendas_percent,
    v_mtd_variacao_mes_anterior_lucro_percent,
    v_mtd_variacao_mes_anterior_margem,
    v_mtd_ano_anterior_vendas,
    v_mtd_ano_anterior_lucro,
    v_mtd_ano_anterior_margem,
    v_mtd_variacao_ano_anterior_vendas_percent,
    v_mtd_variacao_ano_anterior_lucro_percent,
    v_mtd_variacao_ano_anterior_margem;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_ytd_metrics(
  schema_name text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids text[] DEFAULT NULL::text[]
)
RETURNS TABLE(
  ytd_vendas numeric,
  ytd_vendas_ano_anterior numeric,
  ytd_variacao_vendas_percent numeric,
  ytd_lucro numeric,
  ytd_lucro_ano_anterior numeric,
  ytd_variacao_lucro_percent numeric,
  ytd_margem numeric,
  ytd_margem_ano_anterior numeric,
  ytd_variacao_margem numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_data_inicio_ytd DATE;
  v_data_fim_ytd DATE;
  v_data_inicio_ytd_ano_anterior DATE;
  v_data_fim_ytd_ano_anterior DATE;

  v_ytd_vendas NUMERIC := 0;
  v_ytd_lucro NUMERIC := 0;
  v_ytd_margem NUMERIC := 0;

  v_ytd_vendas_ano_anterior NUMERIC := 0;
  v_ytd_lucro_ano_anterior NUMERIC := 0;
  v_ytd_margem_ano_anterior NUMERIC := 0;

  v_ytd_variacao_vendas_percent NUMERIC := 0;
  v_ytd_variacao_lucro_percent NUMERIC := 0;
  v_ytd_variacao_margem NUMERIC := 0;

  v_descontos_ytd NUMERIC := 0;
  v_descontos_ytd_ano_anterior NUMERIC := 0;
  v_table_exists BOOLEAN;
BEGIN
  v_data_inicio_ytd := DATE_TRUNC('year', p_data_inicio)::DATE;

  IF EXTRACT(YEAR FROM p_data_inicio) = EXTRACT(YEAR FROM CURRENT_DATE) THEN
    v_data_fim_ytd := LEAST(p_data_fim, CURRENT_DATE);
  ELSE
    v_data_fim_ytd := p_data_fim;
  END IF;

  v_data_inicio_ytd_ano_anterior := (v_data_inicio_ytd - INTERVAL '1 year')::DATE;
  v_data_fim_ytd_ano_anterior := (v_data_fim_ytd - INTERVAL '1 year')::DATE;

  EXECUTE format('
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = %L AND table_name = ''descontos_venda''
    )', schema_name) INTO v_table_exists;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0) as vendas,
      COALESCE(SUM(total_lucro), 0) as lucro
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_ytd, v_data_fim_ytd, p_filiais_ids
  INTO v_ytd_vendas, v_ytd_lucro;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_ytd, v_data_fim_ytd, p_filiais_ids
    INTO v_descontos_ytd;

    v_ytd_vendas := v_ytd_vendas - v_descontos_ytd;
    v_ytd_lucro := v_ytd_lucro - v_descontos_ytd;
  END IF;

  IF v_ytd_vendas > 0 THEN
    v_ytd_margem := (v_ytd_lucro / v_ytd_vendas) * 100;
  ELSE
    v_ytd_margem := 0;
  END IF;

  EXECUTE format('
    SELECT
      COALESCE(SUM(valor_total), 0) as vendas,
      COALESCE(SUM(total_lucro), 0) as lucro
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN $1 AND $2
      AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
  ', schema_name)
  USING v_data_inicio_ytd_ano_anterior, v_data_fim_ytd_ano_anterior, p_filiais_ids
  INTO v_ytd_vendas_ano_anterior, v_ytd_lucro_ano_anterior;

  IF v_table_exists THEN
    EXECUTE format('
      SELECT COALESCE(SUM(valor_desconto), 0)
      FROM %I.descontos_venda
      WHERE data_desconto BETWEEN $1 AND $2
        AND ($3 IS NULL OR filial_id = ANY($3::INTEGER[]))
    ', schema_name)
    USING v_data_inicio_ytd_ano_anterior, v_data_fim_ytd_ano_anterior, p_filiais_ids
    INTO v_descontos_ytd_ano_anterior;

    v_ytd_vendas_ano_anterior := v_ytd_vendas_ano_anterior - v_descontos_ytd_ano_anterior;
    v_ytd_lucro_ano_anterior := v_ytd_lucro_ano_anterior - v_descontos_ytd_ano_anterior;
  END IF;

  IF v_ytd_vendas_ano_anterior > 0 THEN
    v_ytd_margem_ano_anterior := (v_ytd_lucro_ano_anterior / v_ytd_vendas_ano_anterior) * 100;
  ELSE
    v_ytd_margem_ano_anterior := 0;
  END IF;

  IF v_ytd_vendas_ano_anterior > 0 THEN
    v_ytd_variacao_vendas_percent := ((v_ytd_vendas - v_ytd_vendas_ano_anterior) / v_ytd_vendas_ano_anterior) * 100;
  ELSE
    v_ytd_variacao_vendas_percent := 0;
  END IF;

  IF v_ytd_lucro_ano_anterior > 0 THEN
    v_ytd_variacao_lucro_percent := ((v_ytd_lucro - v_ytd_lucro_ano_anterior) / v_ytd_lucro_ano_anterior) * 100;
  ELSE
    v_ytd_variacao_lucro_percent := 0;
  END IF;

  v_ytd_variacao_margem := v_ytd_margem - v_ytd_margem_ano_anterior;

  RETURN QUERY SELECT
    v_ytd_vendas,
    v_ytd_vendas_ano_anterior,
    v_ytd_variacao_vendas_percent,
    v_ytd_lucro,
    v_ytd_lucro_ano_anterior,
    v_ytd_variacao_lucro_percent,
    v_ytd_margem,
    v_ytd_margem_ano_anterior,
    v_ytd_variacao_margem;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_departamentos_hierarquia(
  p_schema text,
  p_nivel integer,
  p_dept_ids bigint[]
)
RETURNS TABLE(nivel integer, dept_id bigint)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT p_nivel, unnest(p_dept_ids);

  IF p_nivel = 3 THEN
    RETURN QUERY EXECUTE format('
      SELECT 2, departamento_id::BIGINT
      FROM %I.departments_level_2
      WHERE pai_level_3_id = ANY($1)
    ', p_schema) USING p_dept_ids;

    RETURN QUERY EXECUTE format('
      SELECT 1, departamento_id::BIGINT
      FROM %I.departments_level_1
      WHERE pai_level_3_id = ANY($1)
    ', p_schema) USING p_dept_ids;
  END IF;

  IF p_nivel = 2 THEN
    RETURN QUERY EXECUTE format('
      SELECT 1, departamento_id::BIGINT
      FROM %I.departments_level_1
      WHERE pai_level_2_id = ANY($1)
    ', p_schema) USING p_dept_ids;
  END IF;

  RETURN;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_departamentos_hierarquia_simples(
  p_schema text,
  p_nivel integer,
  p_dept_ids bigint[]
)
RETURNS bigint[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result BIGINT[];
BEGIN
  IF p_nivel = 1 THEN
    RETURN p_dept_ids;
  END IF;

  IF p_nivel = 2 THEN
    EXECUTE format('
      SELECT array_agg(DISTINCT departamento_id)
      FROM %I.departments_level_1
      WHERE pai_level_2_id = ANY($1)
    ', p_schema)
    INTO v_result
    USING p_dept_ids;
    RETURN v_result;
  END IF;

  IF p_nivel = 3 THEN
    EXECUTE format('
      SELECT array_agg(DISTINCT departamento_id)
      FROM %I.departments_level_1
      WHERE pai_level_3_id = ANY($1)
    ', p_schema)
    INTO v_result
    USING p_dept_ids;
    RETURN v_result;
  END IF;

  IF p_nivel = 4 THEN
    EXECUTE format('
      SELECT array_agg(DISTINCT departamento_id)
      FROM %I.departments_level_1
      WHERE pai_level_4_id = ANY($1)
    ', p_schema)
    INTO v_result
    USING p_dept_ids;
    RETURN v_result;
  END IF;

  IF p_nivel = 5 THEN
    EXECUTE format('
      SELECT array_agg(DISTINCT departamento_id)
      FROM %I.departments_level_1
      WHERE pai_level_5_id = ANY($1)
    ', p_schema)
    INTO v_result
    USING p_dept_ids;
    RETURN v_result;
  END IF;

  IF p_nivel = 6 THEN
    EXECUTE format('
      SELECT array_agg(DISTINCT departamento_id)
      FROM %I.departments_level_1
      WHERE pai_level_6_id = ANY($1)
    ', p_schema)
    INTO v_result
    USING p_dept_ids;
    RETURN v_result;
  END IF;

  RETURN ARRAY[]::BIGINT[];
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_descontos_venda(p_schema text)
RETURNS TABLE(
  id uuid,
  filial_id integer,
  data_desconto date,
  valor_desconto numeric,
  desconto_custo numeric,
  observacao text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  created_by uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY EXECUTE format(
    'SELECT 
      id,
      filial_id,
      data_desconto,
      valor_desconto,
      COALESCE(desconto_custo, 0) as desconto_custo,
      observacao,
      created_at,
      updated_at,
      created_by
    FROM %I.descontos_venda
    ORDER BY data_desconto DESC, filial_id',
    p_schema
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_despesas_hierarquia(
  p_schema text,
  p_filial_id integer,
  p_data_inicial date,
  p_data_final date,
  p_tipo_data text DEFAULT 'data_despesa'::text
)
RETURNS TABLE(
  dept_id integer,
  dept_descricao text,
  tipo_id integer,
  tipo_descricao text,
  data_emissao date,
  descricao_despesa text,
  id_fornecedor integer,
  numero_nota bigint,
  serie_nota character varying,
  valor numeric,
  usuario character varying,
  observacao text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY EXECUTE format('
    SELECT
      d.id AS dept_id,
      d.descricao AS dept_descricao,
      td.id AS tipo_id,
      td.descricao AS tipo_descricao,
      desp.data_emissao,
      desp.descricao_despesa AS descricao_despesa,
      desp.id_fornecedor,
      desp.numero_nota,
      desp.serie_nota,
      desp.valor,
      desp.usuario,
      desp.observacao
    FROM %I.despesas desp
    INNER JOIN %I.tipos_despesa td ON desp.id_tipo_despesa = td.id
    INNER JOIN %I.departamentos_nivel1 d ON td.departamentalizacao_nivel1 = d.id
    WHERE desp.filial_id = $1
      AND desp.data_despesa BETWEEN $2 AND $3
    ORDER BY d.descricao, td.descricao, desp.data_despesa DESC
  ', p_schema, p_schema, p_schema)
  USING p_filial_id, p_data_inicial, p_data_final;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dre_comparativo_data(
  p_schema text,
  p_filiais_ids integer[],
  p_mes integer,
  p_ano integer
)
RETURNS TABLE(
  receita_bruta_pdv numeric,
  receita_bruta_faturamento numeric,
  receita_bruta numeric,
  desconto_venda numeric,
  receita_liquida numeric,
  cmv_pdv numeric,
  cmv_faturamento numeric,
  cmv numeric,
  lucro_bruto numeric,
  margem_bruta numeric,
  despesas_operacionais numeric,
  resultado_operacional numeric,
  margem_operacional numeric,
  despesas_json jsonb
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT * FROM public.get_dre_comparativo_data_v3(
    p_schema,
    p_filiais_ids,
    p_mes,
    p_ano
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dre_comparativo_data_v2(
  p_schema text,
  p_filiais_ids integer[],
  p_data_inicio date,
  p_data_fim date
)
RETURNS TABLE(
  receita_bruta_pdv numeric,
  receita_bruta_faturamento numeric,
  receita_bruta numeric,
  desconto_venda numeric,
  receita_liquida numeric,
  cmv_pdv numeric,
  cmv_faturamento numeric,
  cmv numeric,
  lucro_bruto numeric,
  margem_bruta numeric,
  despesas_operacionais numeric,
  resultado_operacional numeric,
  margem_operacional numeric,
  despesas_json jsonb
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT * FROM public.get_dre_comparativo_data_v2_v3(
    p_schema,
    p_filiais_ids,
    p_data_inicio,
    p_data_fim
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dre_comparativo_data_v2_v3(
  p_schema text,
  p_filiais_ids integer[],
  p_data_inicio date,
  p_data_fim date
)
RETURNS TABLE(
  receita_bruta_pdv numeric,
  receita_bruta_faturamento numeric,
  receita_bruta numeric,
  desconto_venda numeric,
  receita_liquida numeric,
  cmv_pdv numeric,
  cmv_faturamento numeric,
  cmv numeric,
  lucro_bruto numeric,
  margem_bruta numeric,
  despesas_operacionais numeric,
  resultado_operacional numeric,
  margem_operacional numeric,
  despesas_json jsonb
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_receita_bruta_pdv NUMERIC := 0;
  v_cmv_pdv NUMERIC := 0;
  v_receita_bruta_faturamento NUMERIC := 0;
  v_cmv_faturamento NUMERIC := 0;
  v_receita_bruta NUMERIC := 0;
  v_desconto_venda NUMERIC := 0;
  v_receita_liquida NUMERIC := 0;
  v_cmv NUMERIC := 0;
  v_lucro_bruto NUMERIC := 0;
  v_margem_bruta NUMERIC := 0;
  v_despesas_operacionais NUMERIC := 0;
  v_resultado_operacional NUMERIC := 0;
  v_margem_operacional NUMERIC := 0;
  v_despesas_json JSONB := '[]'::JSONB;
  v_table_exists BOOLEAN;
BEGIN
  IF p_schema IS NULL OR p_schema = '' THEN
    RAISE EXCEPTION 'Schema é obrigatório';
  END IF;

  IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
    RAISE EXCEPTION 'Período de datas é obrigatório';
  END IF;

  IF p_filiais_ids IS NULL OR array_length(p_filiais_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'Ao menos uma filial é obrigatória';
  END IF;

  EXECUTE format(
    'SELECT COALESCE(SUM(valor_total), 0)::NUMERIC 
     FROM %I.vendas_diarias_por_filial 
     WHERE data_venda BETWEEN $1 AND $2 
       AND filial_id = ANY($3)',
    p_schema
  ) INTO v_receita_bruta_pdv
  USING p_data_inicio, p_data_fim, p_filiais_ids;

  EXECUTE format(
    'SELECT COALESCE(SUM(custo_total), 0)::NUMERIC 
     FROM %I.vendas_diarias_por_filial 
     WHERE data_venda BETWEEN $1 AND $2 
       AND filial_id = ANY($3)',
    p_schema
  ) INTO v_cmv_pdv
  USING p_data_inicio, p_data_fim, p_filiais_ids;

  EXECUTE format(
    'SELECT EXISTS (
       SELECT 1 FROM information_schema.tables 
       WHERE table_schema = %L 
         AND table_name = ''faturamento''
     )', p_schema
  ) INTO v_table_exists;

  IF v_table_exists THEN
    EXECUTE format(
      'SELECT COALESCE(SUM(valor_contabil), 0)::NUMERIC 
       FROM (
         SELECT DISTINCT ON (id_saida) id_saida, valor_contabil 
         FROM %I.faturamento 
         WHERE data_saida BETWEEN $1 AND $2 
           AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''') 
           AND filial_id = ANY($3)
       ) n',
      p_schema
    ) INTO v_receita_bruta_faturamento
    USING p_data_inicio, p_data_fim, p_filiais_ids;

    EXECUTE format(
      'SELECT COALESCE(SUM(quantidade * custo_medio), 0)::NUMERIC 
       FROM %I.faturamento 
       WHERE data_saida BETWEEN $1 AND $2 
         AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''') 
         AND filial_id = ANY($3)',
      p_schema
    ) INTO v_cmv_faturamento
    USING p_data_inicio, p_data_fim, p_filiais_ids;
  END IF;

  v_receita_bruta := v_receita_bruta_pdv + v_receita_bruta_faturamento;
  v_cmv := v_cmv_pdv + v_cmv_faturamento;

  EXECUTE format(
    'SELECT EXISTS (
       SELECT 1 FROM information_schema.tables 
       WHERE table_schema = %L 
         AND table_name = ''descontos_venda''
     )',
    p_schema
  ) INTO v_table_exists;

  IF v_table_exists THEN
    EXECUTE format(
      'SELECT COALESCE(SUM(valor_desconto), 0)::NUMERIC 
       FROM %I.descontos_venda 
       WHERE data_desconto BETWEEN $1 AND $2 
         AND filial_id = ANY($3)',
      p_schema
    ) INTO v_desconto_venda
    USING p_data_inicio, p_data_fim, p_filiais_ids;
  END IF;

  v_receita_liquida := v_receita_bruta - v_desconto_venda;
  v_lucro_bruto := v_receita_liquida - v_cmv;

  IF v_receita_liquida > 0 THEN
    v_margem_bruta := (v_lucro_bruto / v_receita_liquida) * 100;
  END IF;

  EXECUTE format('
    WITH despesas_completas AS (
      SELECT
        d.id AS departamento_id,
        d.descricao AS departamento,
        td.id AS tipo_id,
        td.descricao AS tipo,
        desp.descricao_despesa,
        desp.numero_nota,
        desp.serie_nota,
        desp.data_emissao,
        desp.valor
      FROM %I.despesas desp
      INNER JOIN %I.tipos_despesa td ON desp.id_tipo_despesa = td.id
      INNER JOIN %I.departamentos_nivel1 d ON td.departamentalizacao_nivel1 = d.id
      WHERE desp.data_despesa BETWEEN $1 AND $2
        AND desp.filial_id = ANY($3)
    ),
    despesas_agrupadas AS (
      SELECT 
        departamento_id,
        departamento,
        tipo_id,
        tipo,
        jsonb_agg(
          jsonb_build_object(
            ''descricao'', descricao_despesa,
            ''numero_nota'', numero_nota,
            ''serie_nota'', serie_nota,
            ''data_emissao'', data_emissao,
            ''valor'', valor
          ) ORDER BY data_emissao DESC, valor DESC
        ) AS despesas,
        SUM(valor) AS tipo_valor
      FROM despesas_completas
      GROUP BY departamento_id, departamento, tipo_id, tipo
    ),
    tipos_agrupados AS (
      SELECT
        departamento_id,
        departamento,
        jsonb_agg(
          jsonb_build_object(
            ''tipo_id'', tipo_id,
            ''tipo'', tipo,
            ''valor'', tipo_valor,
            ''despesas'', despesas
          ) ORDER BY tipo_valor DESC
        ) AS tipos,
        SUM(tipo_valor) AS dept_valor
      FROM despesas_agrupadas
      GROUP BY departamento_id, departamento
    )
    SELECT 
      COALESCE(SUM(dept_valor), 0)::NUMERIC AS total_despesas,
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            ''departamento_id'', departamento_id,
            ''departamento'', departamento,
            ''valor'', dept_valor,
            ''tipos'', tipos
          ) ORDER BY dept_valor DESC
        ),
        ''[]''::JSONB
      ) AS despesas_json
    FROM tipos_agrupados
  ', p_schema, p_schema, p_schema)
  INTO v_despesas_operacionais, v_despesas_json
  USING p_data_inicio, p_data_fim, p_filiais_ids;

  v_resultado_operacional := v_lucro_bruto - v_despesas_operacionais;

  IF v_receita_liquida > 0 THEN
    v_margem_operacional := (v_resultado_operacional / v_receita_liquida) * 100;
  END IF;

  RETURN QUERY SELECT 
    v_receita_bruta_pdv,
    v_receita_bruta_faturamento,
    v_receita_bruta,
    v_desconto_venda,
    v_receita_liquida,
    v_cmv_pdv,
    v_cmv_faturamento,
    v_cmv,
    v_lucro_bruto,
    v_margem_bruta,
    v_despesas_operacionais,
    v_resultado_operacional,
    v_margem_operacional,
    v_despesas_json;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dre_comparativo_data_v3(
  p_schema text,
  p_filiais_ids integer[],
  p_mes integer,
  p_ano integer
)
RETURNS TABLE(
  receita_bruta_pdv numeric,
  receita_bruta_faturamento numeric,
  receita_bruta numeric,
  desconto_venda numeric,
  receita_liquida numeric,
  cmv_pdv numeric,
  cmv_faturamento numeric,
  cmv numeric,
  lucro_bruto numeric,
  margem_bruta numeric,
  despesas_operacionais numeric,
  resultado_operacional numeric,
  margem_operacional numeric,
  despesas_json jsonb
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_data_inicio DATE;
  v_data_fim DATE;
  v_receita_bruta_pdv NUMERIC := 0;
  v_cmv_pdv NUMERIC := 0;
  v_receita_bruta_faturamento NUMERIC := 0;
  v_cmv_faturamento NUMERIC := 0;
  v_receita_bruta NUMERIC := 0;
  v_desconto_venda NUMERIC := 0;
  v_receita_liquida NUMERIC := 0;
  v_cmv NUMERIC := 0;
  v_lucro_bruto NUMERIC := 0;
  v_margem_bruta NUMERIC := 0;
  v_despesas_operacionais NUMERIC := 0;
  v_resultado_operacional NUMERIC := 0;
  v_margem_operacional NUMERIC := 0;
  v_despesas_json JSONB := '[]'::JSONB;
  v_table_exists BOOLEAN;
BEGIN
  IF p_schema IS NULL OR p_schema = '' THEN
    RAISE EXCEPTION 'Schema é obrigatório';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mês deve estar entre 1 e 12';
  END IF;

  IF p_ano < 2000 OR p_ano > 2100 THEN
    RAISE EXCEPTION 'Ano inválido';
  END IF;

  IF p_filiais_ids IS NULL OR array_length(p_filiais_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'Ao menos uma filial é obrigatória';
  END IF;

  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := (v_data_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  EXECUTE format(
    'SELECT COALESCE(SUM(valor_total), 0)::NUMERIC 
     FROM %I.vendas_diarias_por_filial 
     WHERE data_venda BETWEEN $1 AND $2 
       AND filial_id = ANY($3)',
    p_schema
  ) INTO v_receita_bruta_pdv
  USING v_data_inicio, v_data_fim, p_filiais_ids;

  EXECUTE format(
    'SELECT COALESCE(SUM(custo_total), 0)::NUMERIC 
     FROM %I.vendas_diarias_por_filial 
     WHERE data_venda BETWEEN $1 AND $2 
       AND filial_id = ANY($3)',
    p_schema
  ) INTO v_cmv_pdv
  USING v_data_inicio, v_data_fim, p_filiais_ids;

  EXECUTE format(
    'SELECT EXISTS (
       SELECT 1 FROM information_schema.tables 
       WHERE table_schema = %L 
         AND table_name = ''faturamento''
     )', p_schema
  ) INTO v_table_exists;

  IF v_table_exists THEN
    EXECUTE format(
      'SELECT COALESCE(SUM(valor_contabil), 0)::NUMERIC 
       FROM (
         SELECT DISTINCT ON (id_saida) id_saida, valor_contabil 
         FROM %I.faturamento 
         WHERE data_saida BETWEEN $1 AND $2 
           AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''') 
           AND filial_id = ANY($3)
       ) n',
      p_schema
    ) INTO v_receita_bruta_faturamento
    USING v_data_inicio, v_data_fim, p_filiais_ids;

    EXECUTE format(
      'SELECT COALESCE(SUM(quantidade * custo_medio), 0)::NUMERIC 
       FROM %I.faturamento 
       WHERE data_saida BETWEEN $1 AND $2 
         AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''') 
         AND filial_id = ANY($3)',
      p_schema
    ) INTO v_cmv_faturamento
    USING v_data_inicio, v_data_fim, p_filiais_ids;
  END IF;

  v_receita_bruta := v_receita_bruta_pdv + v_receita_bruta_faturamento;
  v_cmv := v_cmv_pdv + v_cmv_faturamento;

  EXECUTE format(
    'SELECT EXISTS (
       SELECT 1 FROM information_schema.tables 
       WHERE table_schema = %L 
         AND table_name = ''descontos_venda''
     )',
    p_schema
  ) INTO v_table_exists;

  IF v_table_exists THEN
    EXECUTE format(
      'SELECT COALESCE(SUM(valor_desconto), 0)::NUMERIC 
       FROM %I.descontos_venda 
       WHERE data_desconto BETWEEN $1 AND $2 
         AND filial_id = ANY($3)',
      p_schema
    ) INTO v_desconto_venda
    USING v_data_inicio, v_data_fim, p_filiais_ids;
  END IF;

  v_receita_liquida := v_receita_bruta - v_desconto_venda;
  v_lucro_bruto := v_receita_liquida - v_cmv;

  IF v_receita_liquida > 0 THEN
    v_margem_bruta := (v_lucro_bruto / v_receita_liquida) * 100;
  END IF;

  EXECUTE format('
    WITH despesas_completas AS (
      SELECT
        d.id AS departamento_id,
        d.descricao AS departamento,
        td.id AS tipo_id,
        td.descricao AS tipo,
        desp.descricao_despesa,
        desp.numero_nota,
        desp.serie_nota,
        desp.data_emissao,
        desp.valor
      FROM %I.despesas desp
      INNER JOIN %I.tipos_despesa td ON desp.id_tipo_despesa = td.id
      INNER JOIN %I.departamentos_nivel1 d ON td.departamentalizacao_nivel1 = d.id
      WHERE desp.data_despesa BETWEEN $1 AND $2
        AND desp.filial_id = ANY($3)
    ),
    despesas_agrupadas AS (
      SELECT 
        departamento_id,
        departamento,
        tipo_id,
        tipo,
        jsonb_agg(
          jsonb_build_object(
            ''descricao'', descricao_despesa,
            ''numero_nota'', numero_nota,
            ''serie_nota'', serie_nota,
            ''data_emissao'', data_emissao,
            ''valor'', valor
          ) ORDER BY data_emissao DESC, valor DESC
        ) AS despesas,
        SUM(valor) AS tipo_valor
      FROM despesas_completas
      GROUP BY departamento_id, departamento, tipo_id, tipo
    ),
    tipos_agrupados AS (
      SELECT
        departamento_id,
        departamento,
        jsonb_agg(
          jsonb_build_object(
            ''tipo_id'', tipo_id,
            ''tipo'', tipo,
            ''valor'', tipo_valor,
            ''despesas'', despesas
          ) ORDER BY tipo_valor DESC
        ) AS tipos,
        SUM(tipo_valor) AS dept_valor
      FROM despesas_agrupadas
      GROUP BY departamento_id, departamento
    )
    SELECT 
      COALESCE(SUM(dept_valor), 0)::NUMERIC AS total_despesas,
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            ''departamento_id'', departamento_id,
            ''departamento'', departamento,
            ''valor'', dept_valor,
            ''tipos'', tipos
          ) ORDER BY dept_valor DESC
        ),
        ''[]''::JSONB
      ) AS despesas_json
    FROM tipos_agrupados
  ', p_schema, p_schema, p_schema)
  INTO v_despesas_operacionais, v_despesas_json
  USING v_data_inicio, v_data_fim, p_filiais_ids;

  v_resultado_operacional := v_lucro_bruto - v_despesas_operacionais;

  IF v_receita_liquida > 0 THEN
    v_margem_operacional := (v_resultado_operacional / v_receita_liquida) * 100;
  END IF;

  RETURN QUERY SELECT 
    v_receita_bruta_pdv,
    v_receita_bruta_faturamento,
    v_receita_bruta,
    v_desconto_venda,
    v_receita_liquida,
    v_cmv_pdv,
    v_cmv_faturamento,
    v_cmv,
    v_lucro_bruto,
    v_margem_bruta,
    v_despesas_operacionais,
    v_resultado_operacional,
    v_margem_operacional,
    v_despesas_json;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dre_indicadores(
  schema_name text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids text[] DEFAULT NULL::text[]
)
RETURNS TABLE(
  receita_bruta numeric,
  lucro_bruto numeric,
  cmv numeric,
  total_transacoes integer
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  filter_clause TEXT := '';
BEGIN
  IF p_filiais_ids IS NOT NULL AND array_length(p_filiais_ids, 1) > 0 THEN
    filter_clause := format('AND filial_id = ANY(ARRAY[%s]::TEXT[])', array_to_string(p_filiais_ids, ','));
  END IF;

  RETURN QUERY EXECUTE format('
    SELECT 
      COALESCE(SUM(valor_total), 0)::NUMERIC as receita_bruta,
      COALESCE(SUM(total_lucro), 0)::NUMERIC as lucro_bruto,
      COALESCE(SUM(valor_total) - SUM(total_lucro), 0)::NUMERIC as cmv,
      COALESCE(SUM(total_transacoes), 0)::INTEGER as total_transacoes
    FROM %I.vendas_diarias_por_filial
    WHERE data_venda BETWEEN %L AND %L %s
  ', schema_name, p_data_inicio, p_data_fim, filter_clause);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_expenses_by_month_chart(schema_name text, p_filiais text, p_data_inicio date, p_data_fim date, p_filter_type text)
RETURNS TABLE(mes text, total_despesas numeric, total_despesas_ano_anterior numeric)
LANGUAGE plpgsql
AS $function$
DECLARE
  v_query text;
  v_filter_type text := coalesce(p_filter_type, 'year');
  v_start date;
  v_end date;
  v_prev_start date;
  v_prev_end date;
  v_where_clause text := '';
BEGIN
  IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
    v_start := make_date(extract(year from current_date)::int, 1, 1);
    v_end := make_date(extract(year from current_date)::int, 12, 31);
    v_filter_type := 'year';
  ELSE
    IF v_filter_type = 'year' THEN
      v_start := make_date(extract(year from p_data_inicio)::int, 1, 1);
      v_end := make_date(extract(year from p_data_inicio)::int, 12, 31);
    ELSIF v_filter_type = 'month' THEN
      v_start := p_data_inicio;
      v_end := p_data_fim;
    ELSE
      v_start := date_trunc('month', p_data_inicio)::date;
      v_end := (date_trunc('month', p_data_fim) + interval '1 month - 1 day')::date;
    END IF;
  END IF;

  v_prev_start := (v_start - interval '1 year')::date;
  v_prev_end := (v_end - interval '1 year')::date;

  IF p_filiais IS NOT NULL AND p_filiais != 'all' AND p_filiais != '' THEN
    v_where_clause := format('and d.filial_id in (%s)', p_filiais);
  END IF;

  v_query := format($fmt$
    with
    periods as (
      select
        gs::date as period_date,
        case
          when $1 = 'month' then to_char(gs, 'DD')
          when $1 = 'custom' then (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int] || '/' || extract(year from gs)::int
          else (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int]
        end as mes
      from generate_series(
        $2::date,
        $3::date,
        case when $1 = 'month' then interval '1 day' else interval '1 month' end
      ) gs
    ),
    despesas_atual as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, d.data_despesa)::date as period_date,
        coalesce(sum(d.valor), 0) as total
      from %I.despesas d
      where d.data_despesa between $2 and $3
        and d.data_despesa is not null
        and d.valor is not null
        %s
      group by 1
    ),
    despesas_anterior as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, d.data_despesa)::date as period_date,
        coalesce(sum(d.valor), 0) as total
      from %I.despesas d
      where d.data_despesa between $4 and $5
        and d.data_despesa is not null
        and d.valor is not null
        %s
      group by 1
    )
    select
      p.mes,
      coalesce(da.total, 0) as total_despesas,
      coalesce(daa.total, 0) as total_despesas_ano_anterior
    from periods p
    left join despesas_atual da on da.period_date = p.period_date
    left join despesas_anterior daa on daa.period_date = (p.period_date - interval '1 year')::date
    order by p.period_date
  $fmt$,
    schema_name, v_where_clause,
    schema_name, v_where_clause
  );

  return query execute v_query using v_filter_type, v_start, v_end, v_prev_start, v_prev_end;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_faturamento_by_month_chart(schema_name text, p_filiais text, p_data_inicio date, p_data_fim date, p_filter_type text)
RETURNS TABLE(mes text, total_faturamento numeric, total_faturamento_ano_anterior numeric, total_lucro_faturamento numeric, total_lucro_faturamento_ano_anterior numeric)
LANGUAGE plpgsql
AS $function$
DECLARE
  v_filiais_array int[];
  v_table_exists boolean;
  v_filter_type text := coalesce(p_filter_type, 'year');
  v_start date;
  v_end date;
  v_prev_start date;
  v_prev_end date;
BEGIN
  execute format(
    'select exists (
       select 1 from information_schema.tables
       where table_schema = %L and table_name = ''faturamento''
     )', schema_name
  ) into v_table_exists;

  if not v_table_exists then
    return query
    select
      m.mes::text,
      0::numeric as total_faturamento,
      0::numeric as total_faturamento_ano_anterior,
      0::numeric as total_lucro_faturamento,
      0::numeric as total_lucro_faturamento_ano_anterior
    from (
      select unnest(array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez']) as mes
    ) m;
    return;
  end if;

  if p_filiais is null or p_filiais = 'all' or p_filiais = '' then
    v_filiais_array := null;
  else
    v_filiais_array := string_to_array(p_filiais, ',')::int[];
  end if;

  if p_data_inicio is null or p_data_fim is null then
    v_start := make_date(extract(year from current_date)::int, 1, 1);
    v_end := make_date(extract(year from current_date)::int, 12, 31);
    v_filter_type := 'year';
  else
    if v_filter_type = 'year' then
      v_start := make_date(extract(year from p_data_inicio)::int, 1, 1);
      v_end := make_date(extract(year from p_data_inicio)::int, 12, 31);
    elsif v_filter_type = 'month' then
      v_start := p_data_inicio;
      v_end := p_data_fim;
    else
      v_start := date_trunc('month', p_data_inicio)::date;
      v_end := (date_trunc('month', p_data_fim) + interval '1 month - 1 day')::date;
    end if;
  end if;

  v_prev_start := (v_start - interval '1 year')::date;
  v_prev_end := (v_end - interval '1 year')::date;

  return query execute format($q$
    with
    periods as (
      select
        gs::date as period_date,
        case
          when $1 = 'month' then to_char(gs, 'DD')
          when $1 = 'custom' then (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int] || '/' || extract(year from gs)::int
          else (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int]
        end as mes
      from generate_series(
        $2::date,
        $3::date,
        case when $1 = 'month' then interval '1 day' else interval '1 month' end
      ) gs
    ),
    receita_atual as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_saida)::date as period_date,
        sum(valor_contabil) as receita
      from (
        select distinct on (id_saida, date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_saida))
          id_saida, data_saida, valor_contabil
        from %I.faturamento
        where data_saida between $2 and $3
          and (cancelado is null or cancelado = '' or cancelado = ' ')
          and ($4::int[] is null or filial_id = any($4))
      ) notas
      group by 1
    ),
    cmv_atual as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_saida)::date as period_date,
        sum(quantidade * custo_medio) as cmv
      from %I.faturamento
      where data_saida between $2 and $3
        and (cancelado is null or cancelado = '' or cancelado = ' ')
        and ($4::int[] is null or filial_id = any($4))
      group by 1
    ),
    receita_anterior as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_saida)::date as period_date,
        sum(valor_contabil) as receita
      from (
        select distinct on (id_saida, date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_saida))
          id_saida, data_saida, valor_contabil
        from %I.faturamento
        where data_saida between $5 and $6
          and (cancelado is null or cancelado = '' or cancelado = ' ')
          and ($4::int[] is null or filial_id = any($4))
      ) notas
      group by 1
    ),
    cmv_anterior as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_saida)::date as period_date,
        sum(quantidade * custo_medio) as cmv
      from %I.faturamento
      where data_saida between $5 and $6
        and (cancelado is null or cancelado = '' or cancelado = ' ')
        and ($4::int[] is null or filial_id = any($4))
      group by 1
    )
    select
      p.mes,
      coalesce(ra.receita, 0)::numeric as total_faturamento,
      coalesce(rant.receita, 0)::numeric as total_faturamento_ano_anterior,
      coalesce(ra.receita - ca.cmv, 0)::numeric as total_lucro_faturamento,
      coalesce(rant.receita - cant.cmv, 0)::numeric as total_lucro_faturamento_ano_anterior
    from periods p
    left join receita_atual ra on ra.period_date = p.period_date
    left join cmv_atual ca on ca.period_date = p.period_date
    left join receita_anterior rant on rant.period_date = (p.period_date - interval '1 year')::date
    left join cmv_anterior cant on cant.period_date = (p.period_date - interval '1 year')::date
    order by p.period_date
  $q$,
    schema_name, schema_name, schema_name, schema_name
  )
  using v_filter_type, v_start, v_end, v_filiais_array, v_prev_start, v_prev_end;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_faturamento_data(
  p_schema text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids integer[] DEFAULT NULL::integer[]
)
RETURNS TABLE(receita_faturamento numeric, cmv_faturamento numeric, lucro_bruto_faturamento numeric, qtd_notas integer)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_receita NUMERIC := 0;
  v_cmv NUMERIC := 0;
  v_qtd_notas INTEGER := 0;
  v_table_exists BOOLEAN;
BEGIN
  EXECUTE format(
    'SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = %L AND table_name = ''faturamento'')',
    p_schema
  ) INTO v_table_exists;

  IF NOT v_table_exists THEN
    RETURN QUERY SELECT 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::INTEGER;
    RETURN;
  END IF;

  EXECUTE format('
    SELECT COALESCE(SUM(valor_contabil), 0)::NUMERIC
    FROM (
      SELECT DISTINCT ON (id_saida) id_saida, valor_contabil
      FROM %I.faturamento
      WHERE data_saida BETWEEN $1 AND $2
        AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''')
        AND ($3 IS NULL OR filial_id = ANY($3))
    ) notas_unicas
  ', p_schema) INTO v_receita USING p_data_inicio, p_data_fim, p_filiais_ids;

  EXECUTE format('
    SELECT COALESCE(SUM(quantidade * custo_medio), 0)::NUMERIC
    FROM %I.faturamento
    WHERE data_saida BETWEEN $1 AND $2
      AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''')
      AND ($3 IS NULL OR filial_id = ANY($3))
  ', p_schema) INTO v_cmv USING p_data_inicio, p_data_fim, p_filiais_ids;

  EXECUTE format('
    SELECT COUNT(DISTINCT id_saida)::INTEGER
    FROM %I.faturamento
    WHERE data_saida BETWEEN $1 AND $2
      AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''')
      AND ($3 IS NULL OR filial_id = ANY($3))
  ', p_schema) INTO v_qtd_notas USING p_data_inicio, p_data_fim, p_filiais_ids;

  RETURN QUERY SELECT v_receita, v_cmv, (v_receita - v_cmv)::NUMERIC, v_qtd_notas;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_faturamento_por_filial(
  p_schema text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais_ids integer[] DEFAULT NULL::integer[]
)
RETURNS TABLE(filial_id integer, receita_faturamento numeric, cmv_faturamento numeric, lucro_bruto_faturamento numeric)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_table_exists BOOLEAN;
BEGIN
  EXECUTE format(
    'SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = %L AND table_name = ''faturamento'')',
    p_schema
  ) INTO v_table_exists;

  IF NOT v_table_exists THEN
    RETURN;
  END IF;

  RETURN QUERY EXECUTE format('
    WITH notas_unicas AS (
      SELECT DISTINCT ON (id_saida)
        id_saida,
        filial_id as nota_filial_id,
        valor_contabil
      FROM %I.faturamento
      WHERE data_saida BETWEEN $1 AND $2
        AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''')
        AND ($3 IS NULL OR filial_id = ANY($3))
    ),
    receitas AS (
      SELECT
        nota_filial_id as fil_id,
        COALESCE(SUM(valor_contabil), 0) as receita
      FROM notas_unicas
      GROUP BY nota_filial_id
    ),
    custos AS (
      SELECT
        filial_id as fil_id,
        COALESCE(SUM(quantidade * custo_medio), 0) as cmv
      FROM %I.faturamento
      WHERE data_saida BETWEEN $1 AND $2
        AND (cancelado IS NULL OR cancelado = '' '' OR cancelado = '''')
        AND ($3 IS NULL OR filial_id = ANY($3))
      GROUP BY filial_id
    )
    SELECT
      COALESCE(r.fil_id, c.fil_id)::INTEGER as filial_id,
      COALESCE(r.receita, 0)::NUMERIC as receita_faturamento,
      COALESCE(c.cmv, 0)::NUMERIC as cmv_faturamento,
      (COALESCE(r.receita, 0) - COALESCE(c.cmv, 0))::NUMERIC as lucro_bruto_faturamento
    FROM receitas r
    FULL OUTER JOIN custos c ON r.fil_id = c.fil_id
    ORDER BY 1
  ', p_schema, p_schema) USING p_data_inicio, p_data_fim, p_filiais_ids;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_lucro_by_month_chart(schema_name text, p_filiais text, p_data_inicio date, p_data_fim date, p_filter_type text)
RETURNS json
LANGUAGE plpgsql
AS $function$
DECLARE
  result json;
  filial_filter text := '';
  v_filter_type text := coalesce(p_filter_type, 'year');
  v_start date;
  v_end date;
  v_prev_start date;
  v_prev_end date;
BEGIN
  IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
    v_start := make_date(extract(year from current_date)::int, 1, 1);
    v_end := make_date(extract(year from current_date)::int, 12, 31);
    v_filter_type := 'year';
  ELSE
    IF v_filter_type = 'year' THEN
      v_start := make_date(extract(year from p_data_inicio)::int, 1, 1);
      v_end := make_date(extract(year from p_data_inicio)::int, 12, 31);
    ELSIF v_filter_type = 'month' THEN
      v_start := p_data_inicio;
      v_end := p_data_fim;
    ELSE
      v_start := date_trunc('month', p_data_inicio)::date;
      v_end := (date_trunc('month', p_data_fim) + interval '1 month - 1 day')::date;
    END IF;
  END IF;

  v_prev_start := (v_start - interval '1 year')::date;
  v_prev_end := (v_end - interval '1 year')::date;

  IF p_filiais IS NOT NULL AND p_filiais != 'all' AND p_filiais != '' THEN
    filial_filter := format('and vdf.filial_id in (%s)', p_filiais);
  END IF;

  execute format($q$
    with
    periods as (
      select
        gs::date as period_date,
        case
          when $1 = 'month' then to_char(gs, 'DD')
          when $1 = 'custom' then (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int] || '/' || extract(year from gs)::int
          else (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int]
        end as mes
      from generate_series(
        $2::date,
        $3::date,
        case when $1 = 'month' then interval '1 day' else interval '1 month' end
      ) gs
    ),
    lucro_atual as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, vdf.data_venda)::date as period_date,
        coalesce(sum(vdf.total_lucro), 0) as total
      from %I.vendas_diarias_por_filial vdf
      where vdf.data_venda between $2 and $3
      %s
      group by 1
    ),
    lucro_anterior as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, vdf.data_venda)::date as period_date,
        coalesce(sum(vdf.total_lucro), 0) as total
      from %I.vendas_diarias_por_filial vdf
      where vdf.data_venda between $4 and $5
      %s
      group by 1
    )
    select json_agg(t)
    from (
      select
        p.mes,
        coalesce(la.total, 0)::numeric(15,2) as total_lucro,
        coalesce(lb.total, 0)::numeric(15,2) as total_lucro_ano_anterior
      from periods p
      left join lucro_atual la on la.period_date = p.period_date
      left join lucro_anterior lb on lb.period_date = (p.period_date - interval '1 year')::date
      order by p.period_date
    ) t
  $q$,
    schema_name, filial_filter,
    schema_name, filial_filter
  )
  into result
  using v_filter_type, v_start, v_end, v_prev_start, v_prev_end;

  return coalesce(result, '[]'::json);
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_metas_mensais_report(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_filial_id integer DEFAULT NULL::integer,
  p_filial_ids integer[] DEFAULT NULL::integer[]
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result JSON;
  v_query TEXT;
  v_filial_filter TEXT;
  v_data_inicio DATE;
  v_data_fim DATE;
BEGIN
  IF p_schema IS NULL OR p_schema = '' THEN
    RAISE EXCEPTION 'Schema nao informado';
  END IF;

  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := (v_data_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  IF p_filial_ids IS NOT NULL AND array_length(p_filial_ids, 1) > 0 THEN
    v_filial_filter := format('AND m.filial_id = ANY($1)');
  ELSIF p_filial_id IS NOT NULL THEN
    v_filial_filter := format('AND m.filial_id = %s', p_filial_id);
  ELSE
    v_filial_filter := '';
  END IF;

  v_query := format($query$
    WITH metas_periodo AS (
      SELECT
        m.id,
        m.filial_id,
        m.data,
        CASE EXTRACT(DOW FROM m.data)
          WHEN 0 THEN 'Domingo'
          WHEN 1 THEN 'Segunda'
          WHEN 2 THEN 'Terca'
          WHEN 3 THEN 'Quarta'
          WHEN 4 THEN 'Quinta'
          WHEN 5 THEN 'Sexta'
          WHEN 6 THEN 'Sabado'
        END as dia_semana,
        m.meta_percentual,
        m.data_referencia,
        m.valor_referencia,
        m.valor_meta,
        COALESCE(m.valor_realizado, 0) as valor_realizado,
        COALESCE(m.custo_realizado, 0) as custo_realizado,
        COALESCE(m.lucro_realizado, 0) as lucro_realizado,
        (COALESCE(m.valor_realizado, 0) - m.valor_meta) as diferenca,
        CASE
          WHEN m.valor_meta > 0 THEN
            ((COALESCE(m.valor_realizado, 0) - m.valor_meta) / m.valor_meta * 100)
          ELSE 0
        END as diferenca_percentual
      FROM %I.metas_mensais m
      WHERE m.data >= $2
        AND m.data <= $3
        %s
      ORDER BY m.data, m.filial_id
    ),
    totais AS (
      SELECT
        COALESCE(SUM(valor_realizado), 0) as total_realizado,
        COALESCE(SUM(valor_meta), 0) as total_meta,
        COALESCE(SUM(custo_realizado), 0) as total_custo,
        COALESCE(SUM(lucro_realizado), 0) as total_lucro,
        CASE
          WHEN SUM(valor_meta) > 0 THEN
            (SUM(valor_realizado) / SUM(valor_meta) * 100)
          ELSE 0
        END as percentual_atingido,
        CASE
          WHEN SUM(valor_realizado) > 0 THEN
            (SUM(lucro_realizado) / SUM(valor_realizado) * 100)
          ELSE 0
        END as margem_bruta
      FROM metas_periodo
    )
    SELECT json_build_object(
      'metas', COALESCE((SELECT json_agg(row_to_json(metas_periodo)) FROM metas_periodo), '[]'::json),
      'total_realizado', (SELECT total_realizado FROM totais),
      'total_meta', (SELECT total_meta FROM totais),
      'total_custo', (SELECT total_custo FROM totais),
      'total_lucro', (SELECT total_lucro FROM totais),
      'percentual_atingido', (SELECT percentual_atingido FROM totais),
      'margem_bruta', (SELECT margem_bruta FROM totais)
    )
  $query$, p_schema, v_filial_filter);

  IF p_filial_ids IS NOT NULL AND array_length(p_filial_ids, 1) > 0 THEN
    EXECUTE v_query INTO v_result USING p_filial_ids, v_data_inicio, v_data_fim;
  ELSE
    EXECUTE v_query INTO v_result USING v_data_inicio, v_data_fim;
  END IF;

  RETURN COALESCE(v_result, json_build_object(
    'metas', '[]'::json,
    'total_realizado', 0,
    'total_meta', 0,
    'total_custo', 0,
    'total_lucro', 0,
    'percentual_atingido', 0,
    'margem_bruta', 0
  ));
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Erro ao buscar metas: %', SQLERRM;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_metas_setor_report(
  p_schema text,
  p_setor_id bigint,
  p_mes integer,
  p_ano integer,
  p_filial_id bigint DEFAULT NULL::bigint
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result JSON;
  v_departamento_ids_level3 BIGINT[];
  v_departamento_ids_level1 BIGINT[];
  v_dept_ids_text TEXT;
  v_debug_query TEXT;
  v_debug_count BIGINT;
BEGIN
  EXECUTE format('
    SELECT departamento_ids
    FROM %I.setores
    WHERE id = $1
  ', p_schema)
  INTO v_departamento_ids_level3
  USING p_setor_id;

  IF v_departamento_ids_level3 IS NULL OR array_length(v_departamento_ids_level3, 1) IS NULL THEN
    RETURN '[]'::json;
  END IF;

  EXECUTE format('
    SELECT ARRAY_AGG(departamento_id)
    FROM %I.departments_level_1
    WHERE pai_level_3_id = ANY($1)
  ', p_schema)
  INTO v_departamento_ids_level1
  USING v_departamento_ids_level3;

  IF v_departamento_ids_level1 IS NULL OR array_length(v_departamento_ids_level1, 1) IS NULL THEN
    RETURN '[]'::json;
  END IF;

  v_dept_ids_text := array_to_string(v_departamento_ids_level1, ',');

  v_debug_query := format('
    SELECT COUNT(*)
    FROM %I.vendas v
    WHERE EXTRACT(MONTH FROM v.data_venda) = $1
      AND EXTRACT(YEAR FROM v.data_venda) = $2
  ', p_schema);

  EXECUTE v_debug_query INTO v_debug_count USING p_mes, p_ano;

  v_debug_query := format('
    SELECT COUNT(*)
    FROM %I.vendas v
    INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
    WHERE EXTRACT(MONTH FROM v.data_venda) = $1
      AND EXTRACT(YEAR FROM v.data_venda) = $2
      AND p.departamento_id = ANY(ARRAY[%s]::BIGINT[])
  ', p_schema, p_schema, v_dept_ids_text);

  EXECUTE v_debug_query INTO v_debug_count USING p_mes, p_ano;

  IF p_filial_id IS NOT NULL THEN
    v_debug_query := format('
      SELECT COUNT(*)
      FROM %I.vendas v
      INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
      WHERE v.filial_id = $1
        AND EXTRACT(MONTH FROM v.data_venda) = $2
        AND EXTRACT(YEAR FROM v.data_venda) = $3
        AND p.departamento_id = ANY(ARRAY[%s]::BIGINT[])
    ', p_schema, p_schema, v_dept_ids_text);

    EXECUTE v_debug_query INTO v_debug_count USING p_filial_id, p_mes, p_ano;

    EXECUTE format('
      WITH valores_realizados AS (
        SELECT
          v.data_venda,
          v.filial_id,
          SUM(v.valor_vendas) as valor_realizado,
          COUNT(*) as num_vendas
        FROM %I.vendas v
        INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
        WHERE v.filial_id = $1
          AND EXTRACT(MONTH FROM v.data_venda) = $2
          AND EXTRACT(YEAR FROM v.data_venda) = $3
          AND p.departamento_id = ANY(ARRAY[%s]::BIGINT[])
        GROUP BY v.data_venda, v.filial_id
      )
      SELECT COALESCE(json_agg(day_data ORDER BY data), ''[]''::json)
      FROM (
        SELECT
          m.data,
          m.dia_semana,
          json_agg(
            json_build_object(
              ''filial_id'', m.filial_id,
              ''data_referencia'', m.data_referencia,
              ''dia_semana_ref'', COALESCE(m.dia_semana_ref,
                CASE EXTRACT(DOW FROM m.data_referencia)
                  WHEN 0 THEN ''Domingo''
                  WHEN 1 THEN ''Segunda-Feira''
                  WHEN 2 THEN ''Terça-Feira''
                  WHEN 3 THEN ''Quarta-Feira''
                  WHEN 4 THEN ''Quinta-Feira''
                  WHEN 5 THEN ''Sexta-Feira''
                  WHEN 6 THEN ''Sábado''
                END
              ),
              ''valor_referencia'', m.valor_referencia,
              ''meta_percentual'', m.meta_percentual,
              ''valor_meta'', m.valor_meta,
              ''valor_realizado'', COALESCE(vr.valor_realizado, 0),
              ''diferenca'', COALESCE(vr.valor_realizado, 0) - m.valor_meta,
              ''diferenca_percentual'', CASE
                WHEN m.valor_meta > 0 THEN
                  ((COALESCE(vr.valor_realizado, 0) - m.valor_meta) / m.valor_meta) * 100
                ELSE 0
              END,
              ''_debug_num_vendas'', COALESCE(vr.num_vendas, 0),
              ''_debug_data_meta'', m.data::text,
              ''_debug_data_venda'', COALESCE(vr.data_venda::text, ''null'')
            ) ORDER BY m.filial_id
          ) as filiais
        FROM %I.metas_setor m
        LEFT JOIN valores_realizados vr ON vr.data_venda = m.data AND vr.filial_id = m.filial_id
        WHERE m.setor_id = $4
          AND m.filial_id = $1
          AND EXTRACT(MONTH FROM m.data) = $2
          AND EXTRACT(YEAR FROM m.data) = $3
        GROUP BY m.data, m.dia_semana
      ) day_data
    ', p_schema, p_schema, v_dept_ids_text, p_schema)
    INTO v_result
    USING p_filial_id, p_mes, p_ano, p_setor_id;
  ELSE
    EXECUTE format('
      WITH valores_realizados AS (
        SELECT
          v.data_venda,
          v.filial_id,
          SUM(v.valor_vendas) as valor_realizado,
          COUNT(*) as num_vendas
        FROM %I.vendas v
        INNER JOIN %I.produtos p ON v.id_produto = p.id AND v.filial_id = p.filial_id
        WHERE EXTRACT(MONTH FROM v.data_venda) = $1
          AND EXTRACT(YEAR FROM v.data_venda) = $2
          AND p.departamento_id = ANY(ARRAY[%s]::BIGINT[])
        GROUP BY v.data_venda, v.filial_id
      )
      SELECT COALESCE(json_agg(day_data ORDER BY data), ''[]''::json)
      FROM (
        SELECT
          m.data,
          MAX(m.dia_semana) as dia_semana,
          json_agg(
            json_build_object(
              ''filial_id'', m.filial_id,
              ''data_referencia'', m.data_referencia,
              ''dia_semana_ref'', COALESCE(m.dia_semana_ref,
                CASE EXTRACT(DOW FROM m.data_referencia)
                  WHEN 0 THEN ''Domingo''
                  WHEN 1 THEN ''Segunda-Feira''
                  WHEN 2 THEN ''Terça-Feira''
                  WHEN 3 THEN ''Quarta-Feira''
                  WHEN 4 THEN ''Quinta-Feira''
                  WHEN 5 THEN ''Sexta-Feira''
                  WHEN 6 THEN ''Sábado''
                END
              ),
              ''valor_referencia'', m.valor_referencia,
              ''meta_percentual'', m.meta_percentual,
              ''valor_meta'', m.valor_meta,
              ''valor_realizado'', COALESCE(vr.valor_realizado, 0),
              ''diferenca'', COALESCE(vr.valor_realizado, 0) - m.valor_meta,
              ''diferenca_percentual'', CASE
                WHEN m.valor_meta > 0 THEN
                  ((COALESCE(vr.valor_realizado, 0) - m.valor_meta) / m.valor_meta) * 100
                ELSE 0
              END,
              ''_debug_num_vendas'', COALESCE(vr.num_vendas, 0),
              ''_debug_data_meta'', m.data::text,
              ''_debug_data_venda'', COALESCE(vr.data_venda::text, ''null'')
            ) ORDER BY m.filial_id
          ) as filiais
        FROM %I.metas_setor m
        LEFT JOIN valores_realizados vr ON vr.data_venda = m.data AND vr.filial_id = m.filial_id
        WHERE m.setor_id = $3
          AND EXTRACT(MONTH FROM m.data) = $1
          AND EXTRACT(YEAR FROM m.data) = $2
        GROUP BY m.data
      ) day_data
    ', p_schema, p_schema, v_dept_ids_text, p_schema)
    INTO v_result
    USING p_mes, p_ano, p_setor_id;
  END IF;

  RETURN COALESCE(v_result, '[]'::json);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_metas_setor_report_optimized(
  p_schema text,
  p_setor_id bigint,
  p_mes integer,
  p_ano integer,
  p_filial_ids bigint[] DEFAULT NULL::bigint[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '45s'
SET work_mem TO '64MB'
AS $function$
DECLARE
  v_result JSONB;
  v_date_start DATE;
  v_date_end DATE;
  v_query_start TIMESTAMP;
  v_query_duration INTERVAL;
BEGIN
  v_query_start := clock_timestamp();

  IF p_schema IS NULL OR p_setor_id IS NULL OR p_mes IS NULL OR p_ano IS NULL THEN
    RAISE EXCEPTION 'Schema, setor_id, mes e ano sao obrigatorios';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mes invalido: % (deve ser 1-12)', p_mes;
  END IF;

  v_date_start := make_date(p_ano, p_mes, 1);
  v_date_end := v_date_start + INTERVAL '1 month' - INTERVAL '1 day';

  EXECUTE format('
    SELECT COALESCE(json_agg(
      json_build_object(
        ''data'', ms.data,
        ''dia_semana'', ms.dia_semana,
        ''filiais'', (
          SELECT json_agg(
            json_build_object(
              ''filial_id'', msf.filial_id,
              ''filial_nome'', COALESCE(b.descricao, ''Filial '' || msf.filial_id),
              ''data_referencia'', msf.data_referencia,
              ''dia_semana_ref'', msf.dia_semana_ref,
              ''valor_referencia'', COALESCE(msf.valor_referencia, 0),
              ''meta_percentual'', COALESCE(msf.meta_percentual, 0),
              ''valor_meta'', COALESCE(msf.valor_meta, 0),
              ''valor_realizado'', COALESCE(msf.valor_realizado, 0),
              ''custo_realizado'', COALESCE(msf.custo_realizado, 0),
              ''lucro_realizado'', COALESCE(msf.lucro_realizado, 0),
              ''diferenca'', COALESCE(msf.diferenca, 0),
              ''diferenca_percentual'', COALESCE(msf.diferenca_percentual, 0),
              ''percentual_atingido'', CASE
                WHEN COALESCE(msf.valor_meta, 0) > 0 THEN
                  ROUND((COALESCE(msf.valor_realizado, 0) / msf.valor_meta * 100)::numeric, 2)
                ELSE 0
              END
            ) ORDER BY COALESCE(b.descricao, ''Filial '' || msf.filial_id)
          )
          FROM %I.metas_setor msf
          LEFT JOIN public.branches b
            ON b.branch_code = msf.filial_id::text
            AND b.tenant_id = (SELECT id FROM public.tenants WHERE supabase_schema = %L LIMIT 1)
          WHERE msf.setor_id = ms.setor_id
            AND msf.data = ms.data
            AND ($3 IS NULL OR msf.filial_id = ANY($3))
        )
      ) ORDER BY ms.data
    ), ''[]''::json)
    FROM (
      SELECT DISTINCT ms.data, ms.setor_id, ms.dia_semana
      FROM %I.metas_setor ms
      WHERE ms.setor_id = $1
        AND ms.data >= $4
        AND ms.data <= $5
        AND ($3 IS NULL OR ms.filial_id = ANY($3))
    ) ms
  ',
    p_schema,
    p_schema,
    p_schema
  )
  INTO v_result
  USING p_setor_id, p_mes, p_filial_ids, v_date_start, v_date_end;

  v_query_duration := clock_timestamp() - v_query_start;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_metas_setores_report(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_setor_id bigint DEFAULT NULL::bigint,
  p_filial_id bigint DEFAULT NULL::bigint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  EXECUTE format('
    SELECT jsonb_agg(
      jsonb_build_object(
        ''id'', m.id,
        ''setor_id'', m.setor_id,
        ''setor_nome'', s.nome,
        ''filial_id'', m.filial_id,
        ''data'', m.data,
        ''dia_semana'', m.dia_semana,
        ''meta_percentual'', m.meta_percentual,
        ''data_referencia'', m.data_referencia,
        ''valor_referencia'', m.valor_referencia,
        ''valor_meta'', m.valor_meta,
        ''valor_realizado'', m.valor_realizado,
        ''diferenca'', m.diferenca,
        ''diferenca_percentual'', COALESCE(m.diferenca_percentual, 0)
      ) ORDER BY s.nome, m.data, m.filial_id
    )
    FROM %I.metas_setores m
    INNER JOIN %I.setores s ON m.setor_id = s.id
    WHERE EXTRACT(MONTH FROM m.data) = $1
      AND EXTRACT(YEAR FROM m.data) = $2
      AND ($3::bigint IS NULL OR m.setor_id = $3)
      AND ($4::bigint IS NULL OR m.filial_id = $4)
  ', p_schema, p_schema)
  INTO v_result
  USING p_mes, p_ano, p_setor_id, p_filial_id;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE SECURITY DEFINER
AS $function$
  SELECT role FROM user_profiles WHERE id = auth.uid()
$function$;

CREATE OR REPLACE FUNCTION public.get_my_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE SECURITY DEFINER
AS $function$
  SELECT tenant_id FROM user_profiles WHERE id = auth.uid()
$function$;

CREATE OR REPLACE FUNCTION public.get_perdas_report(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_filial_id integer,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50
)
RETURNS TABLE(dept_nivel3 text, dept_nivel2 text, dept_nivel1 text, produto_codigo bigint, produto_descricao text, filial_id integer, qtde numeric, valor_perda numeric)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_sql TEXT;
BEGIN
  IF p_schema IS NULL OR p_schema = '' THEN
    RAISE EXCEPTION 'Schema é obrigatório';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mês deve estar entre 1 e 12';
  END IF;

  IF p_ano < 2000 OR p_ano > 2100 THEN
    RAISE EXCEPTION 'Ano inválido';
  END IF;

  IF p_filial_id IS NULL THEN
    RAISE EXCEPTION 'Filial é obrigatória';
  END IF;

  v_sql := format('
    SELECT
      COALESCE(d3.descricao, ''SEM DEPARTAMENTO'')::TEXT as dept_nivel3,
      COALESCE(d2.descricao, ''SEM GRUPO'')::TEXT as dept_nivel2,
      COALESCE(d1.descricao, ''SEM SUBGRUPO'')::TEXT as dept_nivel1,
      p.id::BIGINT as produto_codigo,
      p.descricao::TEXT as produto_descricao,
      per.filial_id::INTEGER,
      SUM(per.quantidade)::NUMERIC as qtde,
      SUM(per.valor_perda)::NUMERIC as valor_perda
    FROM %I.perdas per
    INNER JOIN %I.produtos p
      ON per.produto_id = p.id
      AND per.filial_id = p.filial_id
    LEFT JOIN %I.departments_level_1 d1
      ON p.departamento_id = d1.departamento_id
    LEFT JOIN %I.departments_level_2 d2
      ON d1.pai_level_2_id = d2.departamento_id
    LEFT JOIN %I.departments_level_3 d3
      ON d1.pai_level_3_id = d3.departamento_id
    WHERE per.filial_id = $1
      AND EXTRACT(MONTH FROM per.data_perda) = $2
      AND EXTRACT(YEAR FROM per.data_perda) = $3
    GROUP BY
      d3.descricao,
      d2.descricao,
      d1.descricao,
      p.id,
      p.descricao,
      per.filial_id
    ORDER BY
      d3.descricao NULLS LAST,
      d2.descricao NULLS LAST,
      d1.descricao NULLS LAST,
      SUM(per.valor_perda) DESC
  ', p_schema, p_schema, p_schema, p_schema, p_schema);

  RETURN QUERY EXECUTE v_sql USING p_filial_id, p_mes, p_ano;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_perdas_total_vendas_periodo(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_filial_id integer
)
RETURNS numeric
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_sql TEXT;
  v_total NUMERIC;
  v_data_inicio DATE;
  v_data_fim DATE;
BEGIN
  IF p_schema IS NULL OR p_schema = '' THEN
    RAISE EXCEPTION 'Schema é obrigatório';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mês deve estar entre 1 e 12';
  END IF;

  IF p_ano < 2000 OR p_ano > 2100 THEN
    RAISE EXCEPTION 'Ano inválido';
  END IF;

  IF p_filial_id IS NULL THEN
    RAISE EXCEPTION 'Filial é obrigatória';
  END IF;

  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := (v_data_inicio + INTERVAL '1 month')::DATE;

  v_sql := 'SELECT COALESCE(SUM(valor_vendas), 0)::NUMERIC FROM ' || quote_ident(p_schema) || '.vendas WHERE filial_id = $1 AND data_venda >= $2 AND data_venda < $3';

  EXECUTE v_sql INTO v_total USING p_filial_id, v_data_inicio, v_data_fim;

  RETURN v_total;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_perdas_vendas_por_departamento(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_filial_id integer
)
RETURNS TABLE(dept_nivel3 text, dept_nivel2 text, dept_nivel1 text, valor_vendas numeric)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_sql TEXT;
  v_data_inicio DATE;
  v_data_fim DATE;
BEGIN
  IF p_schema IS NULL OR p_schema = '' THEN
    RAISE EXCEPTION 'Schema é obrigatório';
  END IF;

  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE EXCEPTION 'Mês deve estar entre 1 e 12';
  END IF;

  IF p_ano < 2000 OR p_ano > 2100 THEN
    RAISE EXCEPTION 'Ano inválido';
  END IF;

  IF p_filial_id IS NULL THEN
    RAISE EXCEPTION 'Filial é obrigatória';
  END IF;

  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := (v_data_inicio + INTERVAL '1 month')::DATE;

  v_sql := format('
    SELECT
      COALESCE(d3.descricao, ''SEM DEPARTAMENTO'')::TEXT as dept_nivel3,
      COALESCE(d2.descricao, ''SEM GRUPO'')::TEXT as dept_nivel2,
      COALESCE(d1.descricao, ''SEM SUBGRUPO'')::TEXT as dept_nivel1,
      COALESCE(SUM(v.valor_vendas), 0)::NUMERIC as valor_vendas
    FROM %I.vendas v
    INNER JOIN %I.produtos p
      ON v.id_produto = p.id
      AND v.filial_id = p.filial_id
    LEFT JOIN %I.departments_level_1 d1
      ON p.departamento_id = d1.departamento_id
    LEFT JOIN %I.departments_level_2 d2
      ON d1.pai_level_2_id = d2.departamento_id
    LEFT JOIN %I.departments_level_3 d3
      ON d1.pai_level_3_id = d3.departamento_id
    WHERE v.filial_id = $1
      AND v.data_venda >= $2
      AND v.data_venda < $3
    GROUP BY
      d3.descricao,
      d2.descricao,
      d1.descricao
    ORDER BY
      d3.descricao NULLS LAST,
      d2.descricao NULLS LAST,
      d1.descricao NULLS LAST
  ', p_schema, p_schema, p_schema, p_schema, p_schema);

  RETURN QUERY EXECUTE v_sql USING p_filial_id, v_data_inicio, v_data_fim;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_previsao_ruptura_report(
  p_schema text,
  p_filial_ids bigint[] DEFAULT NULL::bigint[],
  p_dias_min integer DEFAULT 1,
  p_dias_max integer DEFAULT 7,
  p_curvas text[] DEFAULT ARRAY['A'::text, 'B'::text, 'C'::text],
  p_apenas_ativos boolean DEFAULT true,
  p_busca text DEFAULT NULL::text,
  p_tipo_busca text DEFAULT 'produto'::text,
  p_departamento_ids bigint[] DEFAULT NULL::bigint[],
  p_setor_ids bigint[] DEFAULT NULL::bigint[],
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '60s'
AS $function$
DECLARE
  v_offset integer;
  v_total_records integer;
  v_produtos jsonb;
  v_query text;
  v_count_query text;
  v_busca_pattern text;
  v_setor_dept_ids bigint[];
BEGIN
  v_offset := (p_page - 1) * p_page_size;

  v_busca_pattern := CASE WHEN p_busca IS NOT NULL AND p_busca <> ''
                          THEN '%' || UPPER(p_busca) || '%'
                          ELSE NULL
                     END;

  IF p_setor_ids IS NOT NULL THEN
    EXECUTE format('
      SELECT ARRAY_AGG(DISTINCT dl1.departamento_id)
      FROM %I.setores s
      CROSS JOIN LATERAL (
        SELECT dl1.departamento_id
        FROM %I.departments_level_1 dl1
        WHERE
          (s.departamento_nivel = 1 AND dl1.departamento_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 2 AND dl1.pai_level_2_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 3 AND dl1.pai_level_3_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 4 AND dl1.pai_level_4_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 5 AND dl1.pai_level_5_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 6 AND dl1.pai_level_6_id = ANY(s.departamento_ids))
      ) dl1
      WHERE s.id = ANY($1) AND s.ativo = true
    ', p_schema, p_schema)
    INTO v_setor_dept_ids
    USING p_setor_ids;
  END IF;

  v_count_query := format('
    SELECT COUNT(*)
    FROM %I.produtos p
    LEFT JOIN %I.departments_level_1 d ON d.departamento_id = p.departamento_id
    WHERE
      COALESCE(p.estoque_atual, 0) >= 1
      AND COALESCE(p.venda_media_diaria_60d, 0) > 0
      AND COALESCE(p.dias_de_estoque, 0) > 0
      AND p.dias_de_estoque >= $1
      AND p.dias_de_estoque <= $2
      AND p.curva_abcd = ANY($3)
      AND ($4 = false OR p.ativo = true)
      AND ($5 IS NULL OR p.filial_id = ANY($5))
      AND (
        $6 IS NULL
        OR (
          CASE WHEN $7 = ''departamento''
            THEN UPPER(COALESCE(d.descricao, '''')) LIKE $6
            ELSE UPPER(p.descricao) LIKE $6
          END
        )
      )
      AND ($8 IS NULL OR p.departamento_id = ANY($8))
      AND ($9 IS NULL OR p.departamento_id = ANY($9))
  ', p_schema, p_schema);

  EXECUTE v_count_query
  INTO v_total_records
  USING p_dias_min, p_dias_max, p_curvas, p_apenas_ativos, p_filial_ids, v_busca_pattern, p_tipo_busca, p_departamento_ids, v_setor_dept_ids;

  v_query := format('
    SELECT jsonb_agg(row_to_json(t))
    FROM (
      SELECT
        p.id,
        p.descricao,
        p.filial_id,
        COALESCE(b.descricao, ''Filial '' || p.filial_id) AS filial_nome,
        COALESCE(p.departamento_id, 0) AS departamento_id,
        COALESCE(d.descricao, ''SEM DEPARTAMENTO'') AS departamento_nome,
        p.curva_abcd,
        ROUND(p.estoque_atual::numeric, 2) AS estoque_atual,
        ROUND(p.venda_media_diaria_60d::numeric, 2) AS venda_media_diaria_60d,
        ROUND(p.dias_de_estoque::numeric, 1) AS dias_de_estoque,
        (CURRENT_DATE + p.dias_de_estoque::integer)::date AS previsao_ruptura
      FROM %I.produtos p
      LEFT JOIN public.branches b
        ON b.branch_code = p.filial_id::text
        AND b.tenant_id = (SELECT id FROM public.tenants WHERE supabase_schema = %L LIMIT 1)
      LEFT JOIN %I.departments_level_1 d ON d.departamento_id = p.departamento_id
      WHERE
        COALESCE(p.estoque_atual, 0) >= 1
        AND COALESCE(p.venda_media_diaria_60d, 0) > 0
        AND COALESCE(p.dias_de_estoque, 0) > 0
        AND p.dias_de_estoque >= $1
        AND p.dias_de_estoque <= $2
        AND p.curva_abcd = ANY($3)
        AND ($4 = false OR p.ativo = true)
        AND ($5 IS NULL OR p.filial_id = ANY($5))
        AND (
          $6 IS NULL
          OR (
            CASE WHEN $7 = ''departamento''
              THEN UPPER(COALESCE(d.descricao, '''')) LIKE $6
              ELSE UPPER(p.descricao) LIKE $6
            END
          )
        )
        AND ($8 IS NULL OR p.departamento_id = ANY($8))
        AND ($9 IS NULL OR p.departamento_id = ANY($9))
      ORDER BY
        COALESCE(d.descricao, ''ZZZ SEM DEPARTAMENTO'') ASC,
        p.dias_de_estoque ASC,
        p.curva_abcd ASC
      LIMIT $10 OFFSET $11
    ) t
  ', p_schema, p_schema, p_schema);

  EXECUTE v_query
  INTO v_produtos
  USING p_dias_min, p_dias_max, p_curvas, p_apenas_ativos, p_filial_ids, v_busca_pattern, p_tipo_busca, p_departamento_ids, v_setor_dept_ids, p_page_size, v_offset;

  RETURN jsonb_build_object(
    'total_records', COALESCE(v_total_records, 0),
    'page', p_page,
    'page_size', p_page_size,
    'total_pages', CEIL(COALESCE(v_total_records, 0)::numeric / p_page_size),
    'produtos', COALESCE(v_produtos, '[]'::jsonb)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_produtos_sem_vendas(
  p_schema text,
  p_filiais text DEFAULT 'all'::text,
  p_dias_sem_vendas_min integer DEFAULT 15,
  p_dias_sem_vendas_max integer DEFAULT 90,
  p_data_referencia date DEFAULT CURRENT_DATE,
  p_curva_abc text DEFAULT 'all'::text,
  p_filtro_tipo text DEFAULT 'all'::text,
  p_departamento_ids text DEFAULT NULL::text,
  p_produto_ids text DEFAULT NULL::text,
  p_limit integer DEFAULT 500,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
  filial_id bigint,
  produto_id bigint,
  descricao text,
  estoque_atual numeric,
  data_ultima_venda date,
  preco_custo numeric,
  curva_abcd text,
  curva_lucro character varying,
  dias_sem_venda integer,
  total_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '25s'
AS $function$
DECLARE
  v_filiais_condition TEXT;
  v_curva_condition TEXT;
  v_departamento_condition TEXT;
  v_produto_condition TEXT;
  v_data_limite_min DATE;
  v_data_limite_max DATE;
  v_query TEXT;
BEGIN
  v_data_limite_min := p_data_referencia - p_dias_sem_vendas_max;
  v_data_limite_max := p_data_referencia - p_dias_sem_vendas_min;

  IF p_filiais IS NULL OR p_filiais = 'all' OR p_filiais = '' THEN
    v_filiais_condition := '1=1';
  ELSE
    v_filiais_condition := 'p.filial_id IN (' || p_filiais || ')';
  END IF;

  IF p_curva_abc IS NULL OR p_curva_abc = 'all' OR p_curva_abc = '' THEN
    v_curva_condition := '1=1';
  ELSE
    v_curva_condition := 'p.curva_abcd = ' || quote_literal(p_curva_abc);
  END IF;

  IF p_filtro_tipo = 'departamento' AND p_departamento_ids IS NOT NULL AND p_departamento_ids != '' THEN
    v_departamento_condition := 'p.departamento_id IN (' || p_departamento_ids || ')';
  ELSE
    v_departamento_condition := '1=1';
  END IF;

  IF p_filtro_tipo = 'produto' AND p_produto_ids IS NOT NULL AND p_produto_ids != '' THEN
    v_produto_condition := 'p.id IN (' || p_produto_ids || ')';
  ELSE
    v_produto_condition := '1=1';
  END IF;

  v_query := format('
    WITH 
    produtos_base AS (
      SELECT 
        p.id,
        p.filial_id,
        p.descricao,
        p.estoque_atual,
        p.preco_de_custo,
        p.curva_abcd,
        p.curva_lucro
      FROM %I.produtos p
      WHERE p.ativo = true
        AND p.estoque_atual > 0
        AND %s
        AND %s
        AND %s
        AND %s
      LIMIT 2000
    ),
    ultimas_vendas AS (
      SELECT 
        v.id_produto,
        v.filial_id,
        MAX(v.data_venda) as data_ultima_venda
      FROM %I.vendas v
      WHERE EXISTS (
        SELECT 1 FROM produtos_base pb 
        WHERE pb.id = v.id_produto 
          AND pb.filial_id = v.filial_id
      )
      GROUP BY v.id_produto, v.filial_id
    ),
    produtos_sem_vendas AS (
      SELECT
        p.filial_id::BIGINT,
        p.id::BIGINT as produto_id,
        p.descricao::TEXT,
        p.estoque_atual::NUMERIC(18,6),
        uv.data_ultima_venda::DATE,
        p.preco_de_custo::NUMERIC(15,5),
        p.curva_abcd::TEXT,
        p.curva_lucro::VARCHAR(2),
        CASE 
          WHEN uv.data_ultima_venda IS NULL THEN NULL
          ELSE (CURRENT_DATE - uv.data_ultima_venda)::INTEGER 
        END as dias_sem_venda
      FROM produtos_base p
      LEFT JOIN ultimas_vendas uv 
        ON p.id = uv.id_produto 
        AND p.filial_id = uv.filial_id
      WHERE (
        uv.data_ultima_venda >= $1 
        AND uv.data_ultima_venda <= $2
      )
    ),
    total AS (
      SELECT COUNT(*) as cnt FROM produtos_sem_vendas
    )
    SELECT
      psv.filial_id,
      psv.produto_id,
      psv.descricao,
      psv.estoque_atual,
      psv.data_ultima_venda,
      psv.preco_de_custo,
      psv.curva_abcd,
      psv.curva_lucro,
      psv.dias_sem_venda,
      t.cnt::BIGINT as total_count
    FROM produtos_sem_vendas psv
    CROSS JOIN total t
    ORDER BY psv.dias_sem_venda DESC, psv.produto_id
    LIMIT $3
    OFFSET $4
  ',
  p_schema,
  v_filiais_condition,
  v_curva_condition,
  v_departamento_condition,
  v_produto_condition,
  p_schema
  );

  RETURN QUERY EXECUTE v_query 
    USING v_data_limite_min, v_data_limite_max, p_limit, p_offset;
EXCEPTION
  WHEN query_canceled THEN
    RAISE EXCEPTION 'Query muito lenta. Por favor: 1) Selecione UMA filial específica, 2) Aguarde criação de índices';
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_relatorio_hierarquico_lucro(
  p_schema text,
  p_mes_referencia date,
  p_filial_id integer DEFAULT NULL::integer
)
RETURNS TABLE(
  tipo text,
  nivel integer,
  codigo_produto bigint,
  nome text,
  segmento_pai text,
  quantidade_vendida numeric,
  valor_vendido numeric,
  lucro_total numeric,
  percentual_lucro numeric,
  curva_erp text,
  curva_calculada text,
  curva_lucro text,
  ordem_sort text
)
LANGUAGE plpgsql
AS $function$
DECLARE
  query_sql TEXT;
  filtro_filial TEXT;
  nivel_max INTEGER;
  cte_niveis TEXT := '';
  union_niveis TEXT := '';
  i INTEGER;
BEGIN
  filtro_filial := CASE WHEN p_filial_id IS NOT NULL THEN 'AND filial_id = $2' ELSE '' END;

  EXECUTE format('
    SELECT MAX(
      CASE 
        WHEN segmento_nivel_6 IS NOT NULL AND segmento_nivel_6 != '''' THEN 6
        WHEN segmento_nivel_5 IS NOT NULL AND segmento_nivel_5 != '''' THEN 5
        WHEN segmento_nivel_4 IS NOT NULL AND segmento_nivel_4 != '''' THEN 4
        WHEN segmento_nivel_3 IS NOT NULL AND segmento_nivel_3 != '''' THEN 3
        WHEN segmento_nivel_2 IS NOT NULL AND segmento_nivel_2 != '''' THEN 2
        ELSE 1
      END
    )
    FROM %I.vw_report_curva_abcd
    WHERE mes_referencia = $1 %s
    LIMIT 1
  ', p_schema, filtro_filial)
  INTO nivel_max
  USING p_mes_referencia, p_filial_id;

  IF nivel_max IS NULL THEN
    nivel_max := 3;
  END IF;

  FOR i IN REVERSE nivel_max..1 LOOP
    cte_niveis := cte_niveis || format('
    dados_nivel_%s AS (
      SELECT 
        ''nivel_%s''::TEXT as tipo,
        %s as nivel,
        NULL::BIGINT as codigo_produto,
        segmento_nivel_%s::TEXT as nome,
        %s as segmento_pai,
        SUM(quantidade_vendida) as quantidade_vendida,
        SUM(valor_vendido) as valor_vendido,
        SUM(lucro_total) as lucro_total,
        CASE WHEN SUM(valor_vendido) > 0 THEN (SUM(lucro_total) / SUM(valor_vendido) * 100) ELSE 0 END as percentual_lucro,
        NULL::TEXT as curva_erp,
        NULL::TEXT as curva_calculada,
        NULL::TEXT as curva_lucro,
        %s as ordem_sort
      FROM %I.vw_report_curva_abcd
      WHERE mes_referencia = $1 %s
        AND segmento_nivel_%s IS NOT NULL 
        AND segmento_nivel_%s != ''''
      GROUP BY %s
    )',
      i,
      i,
      i,
      i,
      CASE WHEN i < nivel_max THEN format('segmento_nivel_%s::TEXT', i + 1) ELSE 'NULL::TEXT' END,
      CASE 
        WHEN i = nivel_max THEN format('segmento_nivel_%s::TEXT', i)
        ELSE (
          SELECT string_agg(format('segmento_nivel_%s', j), ' || ''|'' || ' ORDER BY j DESC)
          FROM generate_series(nivel_max, i, -1) j
        )
      END,
      p_schema,
      filtro_filial,
      i,
      i,
      (
        SELECT string_agg(format('segmento_nivel_%s', j), ', ' ORDER BY j DESC)
        FROM generate_series(nivel_max, i, -1) j
      )
    );

    IF i > 1 THEN
      cte_niveis := cte_niveis || ',';
    END IF;

    IF union_niveis != '' THEN
      union_niveis := union_niveis || ' UNION ALL ';
    END IF;
    union_niveis := union_niveis || format('SELECT * FROM dados_nivel_%s', i);
  END LOOP;

  query_sql := format('
    WITH 
    %s,
    dados_produtos AS (
      SELECT 
        ''produto''::TEXT as tipo,
        0 as nivel,
        codigo_produto,
        nome_produto::TEXT as nome,
        segmento_nivel_1::TEXT as segmento_pai,
        quantidade_vendida,
        valor_vendido,
        lucro_total,
        CASE WHEN valor_vendido > 0 THEN (lucro_total / valor_vendido * 100) ELSE 0 END as percentual_lucro,
        curva_erp::TEXT,
        curva_calculada::TEXT,
        curva_lucro::TEXT,
        (%s || ''|'' || LPAD(valor_vendido::TEXT, 20, ''0''))::TEXT as ordem_sort
      FROM %I.vw_report_curva_abcd
      WHERE mes_referencia = $1 %s
    )
    %s
    UNION ALL
    SELECT * FROM dados_produtos
    ORDER BY ordem_sort, nivel DESC',
    cte_niveis,
    (
      SELECT string_agg(format('segmento_nivel_%s', j), ' || ''|'' || ' ORDER BY j DESC)
      FROM generate_series(nivel_max, 1, -1) j
    ),
    p_schema,
    filtro_filial,
    union_niveis
  );

  RETURN QUERY EXECUTE query_sql USING p_mes_referencia, p_filial_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_relatorio_venda_curva(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_filial_id text DEFAULT NULL::text,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result jsonb;
  v_offset INTEGER;
  v_filial_filter TEXT;
  v_query TEXT;
BEGIN
  v_offset := (p_page - 1) * p_page_size;

  IF p_filial_id IS NOT NULL AND p_filial_id != 'all' THEN
    v_filial_filter := format('AND v.filial_id = %L::bigint', p_filial_id);
  ELSE
    v_filial_filter := '';
  END IF;

  v_query := format('
    WITH vendas_base AS (
      SELECT 
        v.filial_id,
        v.filial_id::text as filial_nome,
        p.id as produto_id,
        p.descricao as produto_descricao,
        p.departamento_id,
        d1.descricao as dept1_nome,
        d1.pai_level_2_id,
        COALESCE(d2.descricao, ''Sem Departamento Nível 2'') as dept2_nome,
        d1.pai_level_3_id,
        COALESCE(d3.descricao, ''Sem Departamento Nível 3'') as dept3_nome,
        SUM(v.quantidade) as quantidade_total,
        SUM(v.valor_vendas) as total_vendas,
        SUM(COALESCE(v.custo_compra, 0) * COALESCE(v.quantidade, 0)) as total_custo,
        SUM(COALESCE(v.valor_vendas, 0) - (COALESCE(v.custo_compra, 0) * COALESCE(v.quantidade, 0))) as total_lucro,
        COALESCE(p.curva_abcd, ''D'') as curva_venda,
        COALESCE(p.curva_lucro, ''D'') as curva_lucro
      FROM %I.vendas v
      INNER JOIN %I.produtos p ON p.id = v.id_produto AND p.filial_id = v.filial_id
      INNER JOIN %I.departments_level_1 d1 ON d1.departamento_id = p.departamento_id
      LEFT JOIN %I.departments_level_2 d2 ON d2.departamento_id = d1.pai_level_2_id
      LEFT JOIN %I.departments_level_3 d3 ON d3.departamento_id = d1.pai_level_3_id
      WHERE EXTRACT(MONTH FROM v.data_venda) = $1
        AND EXTRACT(YEAR FROM v.data_venda) = $2
        AND v.valor_vendas > 0
        AND p.ativo = true
        %s
      GROUP BY 
        v.filial_id, p.id, p.descricao, p.departamento_id,
        d1.descricao, d1.pai_level_2_id, d2.descricao, d1.pai_level_3_id, d3.descricao,
        p.curva_abcd, p.curva_lucro
    ),
    totais_dept3 AS (
      SELECT 
        COALESCE(pai_level_3_id, 0) as dept3_id,
        dept3_nome,
        COALESCE(pai_level_2_id, 0) as dept2_id,
        dept2_nome,
        SUM(total_vendas) as total_vendas,
        SUM(total_lucro) as total_lucro,
        CASE 
          WHEN SUM(total_vendas) > 0 
          THEN ROUND((SUM(total_lucro) / SUM(total_vendas)) * 100, 2)
          ELSE 0 
        END as margem
      FROM vendas_base
      GROUP BY COALESCE(pai_level_3_id, 0), dept3_nome, COALESCE(pai_level_2_id, 0), dept2_nome
    ),
    totais_dept2 AS (
      SELECT 
        COALESCE(pai_level_2_id, 0) as dept2_id,
        dept2_nome,
        SUM(total_vendas) as total_vendas,
        SUM(total_lucro) as total_lucro,
        CASE 
          WHEN SUM(total_vendas) > 0 
          THEN ROUND((SUM(total_lucro) / SUM(total_vendas)) * 100, 2)
          ELSE 0 
        END as margem
      FROM vendas_base
      GROUP BY COALESCE(pai_level_2_id, 0), dept2_nome
    ),
    totais_dept1 AS (
      SELECT 
        departamento_id as dept1_id,
        dept1_nome,
        SUM(total_vendas) as total_vendas,
        SUM(total_lucro) as total_lucro,
        CASE 
          WHEN SUM(total_vendas) > 0 
          THEN ROUND((SUM(total_lucro) / SUM(total_vendas)) * 100, 2)
          ELSE 0 
        END as margem
      FROM vendas_base
      GROUP BY departamento_id, dept1_nome
    ),
    dept3_paginado AS (
      SELECT dept3_id, dept3_nome, dept2_id, dept2_nome, total_vendas, total_lucro, margem,
             ROW_NUMBER() OVER (ORDER BY total_vendas DESC) as rn
      FROM totais_dept3
    )
    SELECT jsonb_build_object(
      ''total_records'', (SELECT COUNT(*) FROM totais_dept3),
      ''page'', $5,
      ''page_size'', $6,
      ''total_pages'', CEIL((SELECT COUNT(*)::NUMERIC FROM totais_dept3) / $6),
      ''departamentos_nivel1'', (
        SELECT COALESCE(jsonb_agg(dept1_obj ORDER BY total_vendas DESC), ''[]''::jsonb)
        FROM (
          SELECT jsonb_build_object(
            ''departamento_id'', td1.dept1_id,
            ''departamento_nome'', td1.dept1_nome,
            ''valor_venda'', ROUND(td1.total_vendas::numeric, 2),
            ''valor_lucro'', ROUND(td1.total_lucro::numeric, 2),
            ''margem'', td1.margem,
            ''departamentos_nivel2'', (
              SELECT COALESCE(jsonb_agg(dept2_obj ORDER BY total_vendas DESC), ''[]''::jsonb)
              FROM (
                SELECT jsonb_build_object(
                  ''departamento_id'', td2.dept2_id,
                  ''departamento_nome'', td2.dept2_nome,
                  ''valor_venda'', ROUND(td2.total_vendas::numeric, 2),
                  ''valor_lucro'', ROUND(td2.total_lucro::numeric, 2),
                  ''margem'', td2.margem,
                  ''departamentos_nivel3'', (
                    SELECT COALESCE(jsonb_agg(dept3_obj ORDER BY total_vendas DESC), ''[]''::jsonb)
                    FROM (
                      SELECT jsonb_build_object(
                        ''departamento_id'', td3.dept3_id,
                        ''departamento_nome'', td3.dept3_nome,
                        ''valor_venda'', ROUND(td3.total_vendas::numeric, 2),
                        ''valor_lucro'', ROUND(td3.total_lucro::numeric, 2),
                        ''margem'', td3.margem,
                        ''produtos'', (
                          SELECT COALESCE(jsonb_agg(
                            jsonb_build_object(
                              ''produto_id'', vb.produto_id,
                              ''filial_id'', vb.filial_id,
                              ''filial_nome'', vb.filial_nome,
                              ''codigo'', vb.produto_id,
                              ''descricao'', vb.produto_descricao,
                              ''quantidade'', ROUND(vb.quantidade_total::numeric, 2),
                              ''valor_venda'', ROUND(vb.total_vendas::numeric, 2),
                              ''curva_venda'', vb.curva_venda,
                              ''valor_lucro'', ROUND(vb.total_lucro::numeric, 2),
                              ''percentual_lucro'', CASE 
                                WHEN vb.total_vendas > 0 
                                THEN ROUND((vb.total_lucro / vb.total_vendas) * 100, 2)
                                ELSE 0 
                              END,
                              ''curva_lucro'', vb.curva_lucro
                            )
                            ORDER BY 
                              CASE vb.curva_venda 
                                WHEN ''A'' THEN 1 
                                WHEN ''C'' THEN 2 
                                WHEN ''B'' THEN 3 
                                WHEN ''D'' THEN 4 
                                ELSE 5 
                              END,
                              vb.total_vendas DESC
                          ), ''[]''::jsonb)
                          FROM vendas_base vb
                          WHERE COALESCE(vb.pai_level_3_id, 0) = td3.dept3_id
                        )
                      ) as dept3_obj
                      FROM dept3_paginado td3
                      WHERE td3.dept2_id = td2.dept2_id
                        AND td3.rn > $3 
                        AND td3.rn <= $3 + $6
                    ) dept3_sub
                  )
                ) as dept2_obj
                FROM totais_dept2 td2
                WHERE EXISTS (
                  SELECT 1 FROM vendas_base vb 
                  WHERE COALESCE(vb.pai_level_2_id, 0) = td2.dept2_id 
                    AND vb.departamento_id = td1.dept1_id
                )
              ) dept2_sub
            )
          ) as dept1_obj
          FROM totais_dept1 td1
          WHERE EXISTS (
            SELECT 1 FROM dept3_paginado 
            WHERE rn > $3 AND rn <= $3 + $6
              AND EXISTS (
                SELECT 1 FROM vendas_base vb2
                WHERE vb2.departamento_id = td1.dept1_id
              )
          )
        ) dept1_sub
      )
    )
  ', p_schema, p_schema, p_schema, p_schema, p_schema, v_filial_filter);

  EXECUTE v_query
  INTO v_result
  USING p_mes, p_ano, v_offset, v_offset, p_page, p_page_size;

  RETURN COALESCE(v_result, '{"departamentos_nivel1": [], "total_records": 0, "page": 1, "page_size": 50, "total_pages": 0}'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_report_curva_abcd(p_schema_name text, p_mes_ano text, p_filial_id integer DEFAULT NULL::integer)
RETURNS TABLE(mes_referencia date, filial_id bigint, codigo_produto bigint, nome_produto text, curva_erp text, curva_calculada text, quantidade_vendida numeric, valor_vendido numeric, segmento_nivel_1 text, segmento_nivel_2 text, segmento_nivel_3 text, segmento_nivel_4 text, segmento_nivel_5 text, segmento_nivel_6 text)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  target_date DATE;
  query_text TEXT;
BEGIN
  target_date := to_date(p_mes_ano, 'MM/YYYY');

  query_text := format('SELECT * FROM %I.vw_report_curva_abcd WHERE mes_referencia = %L', p_schema_name, target_date);

  IF p_filial_id IS NOT NULL THEN
    query_text := query_text || format(' AND filial_id = %L', p_filial_id);
  END IF;

  RETURN QUERY EXECUTE query_text;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_report_data_from_view(p_schema_name text, p_mes_ano text, p_filial_id integer DEFAULT NULL::integer)
RETURNS TABLE(mes_referencia date, filial_id bigint, codigo_produto bigint, nome_produto text, curva_erp text, curva_calculada text, curva_lucro character varying, quantidade_vendida numeric, valor_vendido numeric, lucro_total numeric, segmento_nivel_1 text, segmento_nivel_2 text, segmento_nivel_3 text, segmento_nivel_4 text, segmento_nivel_5 text, segmento_nivel_6 text)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  target_date DATE;
  query_text TEXT;
BEGIN
  SET search_path = '';
  target_date := to_date(p_mes_ano, 'MM/YYYY');

  query_text := format('SELECT * FROM %I.vw_report_curva_abcd WHERE mes_referencia = %L', p_schema_name, target_date);

  IF p_filial_id IS NOT NULL THEN
    query_text := query_text || format(' AND filial_id = %L', p_filial_id);
  END IF;

  RETURN QUERY EXECUTE query_text;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_ruptura_abcd_report(
  p_schema text,
  p_filial_ids bigint[] DEFAULT NULL::bigint[],
  p_curvas text[] DEFAULT ARRAY['A'::text, 'B'::text],
  p_apenas_ativos boolean DEFAULT true,
  p_apenas_ruptura boolean DEFAULT true,
  p_departamento_ids bigint[] DEFAULT NULL::bigint[],
  p_setor_ids bigint[] DEFAULT NULL::bigint[],
  p_busca text DEFAULT NULL::text,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50
)
RETURNS TABLE(
  total_records bigint,
  departamento_id bigint,
  departamento_nome text,
  produto_id bigint,
  filial_id bigint,
  filial_nome text,
  produto_descricao text,
  curva_lucro character varying,
  curva_venda text,
  estoque_atual numeric,
  venda_media_diaria_60d numeric,
  dias_de_estoque numeric,
  preco_venda numeric,
  filial_transfer_id bigint,
  filial_transfer_nome text,
  estoque_transfer numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '60s'
AS $function$
DECLARE
  v_offset INTEGER;
  v_sql TEXT;
  v_setor_dept_ids bigint[];
  v_final_dept_ids bigint[];
BEGIN
  v_offset := (p_page - 1) * p_page_size;

  IF p_setor_ids IS NOT NULL THEN
    EXECUTE format('
      SELECT ARRAY_AGG(DISTINCT dl1.departamento_id)
      FROM %I.setores s
      CROSS JOIN LATERAL (
        SELECT dl1.departamento_id
        FROM %I.departments_level_1 dl1
        WHERE
          (s.departamento_nivel = 1 AND dl1.departamento_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 2 AND dl1.pai_level_2_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 3 AND dl1.pai_level_3_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 4 AND dl1.pai_level_4_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 5 AND dl1.pai_level_5_id = ANY(s.departamento_ids))
          OR (s.departamento_nivel = 6 AND dl1.pai_level_6_id = ANY(s.departamento_ids))
      ) dl1
      WHERE s.id = ANY($1) AND s.ativo = true
    ', p_schema, p_schema)
    INTO v_setor_dept_ids
    USING p_setor_ids;
  END IF;

  IF p_departamento_ids IS NOT NULL AND v_setor_dept_ids IS NOT NULL THEN
    SELECT ARRAY_AGG(d)
    FROM unnest(p_departamento_ids) d
    WHERE d = ANY(v_setor_dept_ids)
    INTO v_final_dept_ids;
  ELSIF v_setor_dept_ids IS NOT NULL THEN
    v_final_dept_ids := v_setor_dept_ids;
  ELSE
    v_final_dept_ids := p_departamento_ids;
  END IF;

  v_sql := format($sql$
    WITH filtered_produtos AS (
      SELECT
        p.id,
        p.filial_id,
        p.descricao,
        p.curva_lucro,
        p.curva_abcd,
        p.estoque_atual,
        p.venda_media_diaria_60d,
        p.dias_de_estoque,
        p.preco_de_venda_1,
        p.departamento_id
      FROM %I.produtos p
      WHERE 1=1
        AND (CASE WHEN $1 IS NULL THEN TRUE ELSE p.filial_id = ANY($1) END)
        AND (CASE WHEN $2 = TRUE THEN p.ativo = TRUE ELSE TRUE END)
        AND (CASE WHEN $3 = TRUE THEN p.estoque_atual <= 0 ELSE TRUE END)
        AND p.curva_abcd = ANY($4)
        AND (CASE WHEN $5 IS NULL THEN TRUE ELSE p.departamento_id = ANY($5) END)
        AND (CASE WHEN $6 IS NULL OR $6 = '' THEN TRUE ELSE p.descricao ILIKE '%%' || $6 || '%%' END)
    ),
    with_total AS (
      SELECT COUNT(*) as total FROM filtered_produtos
    ),
    tenant_info AS (
      SELECT tenant_id FROM branches LIMIT 1
    ),
    with_transfer_all AS (
      SELECT
        p.id as produto_origem_id,
        p.filial_id as filial_origem_id,
        pt.filial_id as filial_transfer_id,
        COALESCE(f.descricao::TEXT, 'Filial ' || pt.filial_id::TEXT) as filial_transfer_nome,
        pt.estoque_atual as estoque_transfer,
        ROW_NUMBER() OVER (PARTITION BY p.id, p.filial_id ORDER BY pt.estoque_atual DESC, pt.filial_id ASC) as rn
      FROM filtered_produtos p
      INNER JOIN %I.produtos pt
        ON p.id = pt.id
        AND pt.filial_id != p.filial_id
        AND pt.estoque_atual > 0
      LEFT JOIN branches f
        ON pt.filial_id::TEXT = f.branch_code
        AND f.tenant_id = (SELECT tenant_id FROM tenant_info)
    ),
    with_transfer AS (
      SELECT
        produto_origem_id,
        filial_origem_id,
        filial_transfer_id,
        filial_transfer_nome,
        estoque_transfer
      FROM with_transfer_all
      WHERE rn = 1
    )
    SELECT
      (SELECT total FROM with_total) as total_records,
      COALESCE(d.departamento_id, 0) as departamento_id,
      COALESCE(d.descricao, 'SEM DEPARTAMENTO') as departamento_nome,
      fp.id as produto_id,
      fp.filial_id,
      COALESCE(b.descricao::TEXT, 'Filial ' || fp.filial_id::TEXT) as filial_nome,
      fp.descricao as produto_descricao,
      fp.curva_lucro,
      fp.curva_abcd as curva_venda,
      fp.estoque_atual,
      fp.venda_media_diaria_60d,
      fp.dias_de_estoque,
      fp.preco_de_venda_1 as preco_venda,
      wt.filial_transfer_id,
      wt.filial_transfer_nome,
      wt.estoque_transfer
    FROM filtered_produtos fp
    LEFT JOIN %I.departments_level_1 d ON fp.departamento_id = d.departamento_id
    LEFT JOIN branches b
      ON fp.filial_id::TEXT = b.branch_code
      AND b.tenant_id = (SELECT tenant_id FROM tenant_info)
    LEFT JOIN with_transfer wt
      ON fp.id = wt.produto_origem_id
      AND fp.filial_id = wt.filial_origem_id
    ORDER BY
      COALESCE(d.descricao, 'ZZZZZ_SEM DEPARTAMENTO') ASC,
      COALESCE(b.descricao, 'ZZZZ_Filial ' || fp.filial_id::TEXT) ASC,
      fp.descricao ASC
    LIMIT $7 OFFSET $8
  $sql$, p_schema, p_schema, p_schema);

  RETURN QUERY EXECUTE v_sql
  USING p_filial_ids, p_apenas_ativos, p_apenas_ruptura, p_curvas, v_final_dept_ids, p_busca, p_page_size, v_offset;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_ruptura_curva_a(p_schema text, p_filial_id bigint)
RETURNS TABLE(id bigint, descricao text, estoque_atual numeric, departamento_id bigint, departamento_nome text)
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '30s'
AS $function$
BEGIN
  IF p_schema NOT IN ('okilao', 'saoluiz', 'paraiso', 'sol') THEN
    RAISE EXCEPTION 'Schema inválido: %', p_schema;
  END IF;

  RETURN QUERY EXECUTE format('
    SELECT
      p.id,
      p.descricao,
      COALESCE(p.estoque_atual, 0) as estoque_atual,
      COALESCE(p.departamento_id, 0) as departamento_id,
      COALESCE(d.descricao, ''Sem Departamento'') as departamento_nome
    FROM %I.produtos p
    LEFT JOIN %I.departments_level_1 d
      ON p.departamento_id = d.departamento_id
    WHERE
      p.filial_id = $1
      AND p.curva_abcd = ''A''
      AND COALESCE(p.estoque_atual, 0) <= 0
      AND COALESCE(p.ativo, true) = true
    ORDER BY
      COALESCE(d.descricao, ''Sem Departamento'') ASC,
      p.descricao ASC
  ', p_schema, p_schema)
  USING p_filial_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_ruptura_venda_60d_report(
  schema_name text,
  p_filiais integer[] DEFAULT NULL::integer[],
  p_limite_minimo_dias integer DEFAULT 20,
  p_curvas text[] DEFAULT ARRAY['A'::text, 'B'::text, 'C'::text],
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50,
  p_departamento_ids bigint[] DEFAULT NULL::bigint[],
  p_setor_ids bigint[] DEFAULT NULL::bigint[],
  p_busca text DEFAULT NULL::text
)
RETURNS TABLE(total_records bigint, page integer, page_size integer, total_pages integer, departamentos json)
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '120s'
AS $function$
DECLARE
  v_offset integer;
  v_total_records bigint;
  v_total_pages integer;
  v_query text;
  v_count_query text;
  v_result json;
  v_departamento_filter_ids bigint[];
BEGIN
  IF schema_name IS NULL OR schema_name = '' THEN
    RAISE EXCEPTION 'schema_name não pode ser nulo ou vazio';
  END IF;

  v_offset := (p_page - 1) * p_page_size;

  IF p_setor_ids IS NOT NULL AND array_length(p_setor_ids, 1) > 0 THEN
    EXECUTE
      'SELECT COALESCE(ARRAY_AGG(DISTINCT dl1.departamento_id), ARRAY[]::bigint[])
       FROM ' || quote_ident(schema_name) || '.departments_level_1 dl1
       JOIN ' || quote_ident(schema_name) || '.setores s ON s.id = ANY($1)
       WHERE s.ativo = true AND (
         (s.departamento_nivel = 1 AND dl1.departamento_id = ANY(s.departamento_ids)) OR
         (s.departamento_nivel = 2 AND dl1.pai_level_2_id = ANY(s.departamento_ids)) OR
         (s.departamento_nivel = 3 AND dl1.pai_level_3_id = ANY(s.departamento_ids)) OR
         (s.departamento_nivel = 4 AND dl1.pai_level_4_id = ANY(s.departamento_ids)) OR
         (s.departamento_nivel = 5 AND dl1.pai_level_5_id = ANY(s.departamento_ids)) OR
         (s.departamento_nivel = 6 AND dl1.pai_level_6_id = ANY(s.departamento_ids))
       )'
    INTO v_departamento_filter_ids
    USING p_setor_ids;
  END IF;

  IF p_departamento_ids IS NOT NULL AND array_length(p_departamento_ids, 1) > 0 THEN
    v_departamento_filter_ids := p_departamento_ids;
  END IF;

  v_count_query :=
    'SELECT COUNT(*)
     FROM ' || quote_ident(schema_name) || '.produtos p
     LEFT JOIN ' || quote_ident(schema_name) || '.departments_level_1 d1 ON d1.departamento_id = p.departamento_id
     WHERE
       COALESCE(p.dias_com_venda_60d, 0) >= $1
       AND COALESCE(p.dias_com_venda_ultimos_3d, 0) = 0
       AND COALESCE(p.estoque_atual, 0) > 0
       AND ($2 IS NULL OR p.curva_abcd = ANY($2))
       AND ($3 IS NULL OR d1.departamento_id = ANY($3))
       AND (
         $4 IS NULL
         OR p.id::text = $4
         OR p.descricao ILIKE ''%'' || $4 || ''%''
       )
       AND ($5 IS NULL OR p.filial_id = ANY($5))';

  EXECUTE v_count_query
    INTO v_total_records
    USING p_limite_minimo_dias, p_curvas, v_departamento_filter_ids, p_busca, p_filiais;

  v_total_pages := GREATEST(CEIL(COALESCE(v_total_records, 0)::numeric / p_page_size), 1);

  v_query :=
    'WITH produtos_ruptura AS (
       SELECT
         p.id as produto_id,
         p.filial_id,
         COALESCE(b.descricao, ''Filial '' || p.filial_id) as filial_nome,
         COALESCE(p.descricao, ''Sem Descrição'') as produto_nome,
         COALESCE(d1.departamento_id, 0) as departamento_id,
         COALESCE(d1.descricao, ''Sem Departamento'') as departamento_nome,
         COALESCE(p.curva_abcd, ''N/A'') as curva_abcd,
         COALESCE(p.dias_com_venda_60d, 0) as dias_com_venda_60d,
         COALESCE(p.dias_com_venda_ultimos_3d, 0) as dias_com_venda_ultimos_3d,
         COALESCE(p.estoque_atual, 0) as estoque_atual,
         COALESCE(p.venda_media_diaria_60d, 0) as venda_media_diaria_60d,
         (COALESCE(p.estoque_atual, 0) * COALESCE(p.preco_de_custo, 0)) as valor_estoque_parado,
         CASE
           WHEN p.dias_com_venda_60d >= 50 AND p.curva_abcd = ''A'' THEN ''CRÍTICO''
           WHEN p.dias_com_venda_60d >= 40 AND p.curva_abcd IN (''A'', ''B'') THEN ''ALTO''
           WHEN p.dias_com_venda_60d >= 30 THEN ''MÉDIO''
           WHEN p.dias_com_venda_60d >= 20 THEN ''BAIXO''
           ELSE ''NORMAL''
         END as nivel_ruptura,
         CASE
           WHEN p.dias_com_venda_60d >= 50 AND p.curva_abcd = ''A'' THEN 5
           WHEN p.dias_com_venda_60d >= 40 AND p.curva_abcd IN (''A'', ''B'') THEN 4
           WHEN p.dias_com_venda_60d >= 30 THEN 3
           WHEN p.dias_com_venda_60d >= 20 THEN 2
           ELSE 1
         END as nivel_score
       FROM ' || quote_ident(schema_name) || '.produtos p
       LEFT JOIN ' || quote_ident(schema_name) || '.departments_level_1 d1 ON d1.departamento_id = p.departamento_id
       LEFT JOIN public.branches b
         ON b.branch_code = p.filial_id::text
         AND b.tenant_id = (SELECT id FROM public.tenants WHERE supabase_schema = ' || quote_literal(schema_name) || ' LIMIT 1)
       WHERE
         COALESCE(p.dias_com_venda_60d, 0) >= $1
         AND COALESCE(p.dias_com_venda_ultimos_3d, 0) = 0
         AND COALESCE(p.estoque_atual, 0) > 0
         AND ($2 IS NULL OR p.curva_abcd = ANY($2))
         AND ($3 IS NULL OR d1.departamento_id = ANY($3))
         AND (
           $4 IS NULL
           OR p.id::text = $4
           OR p.descricao ILIKE ''%'' || $4 || ''%''
         )
         AND ($5 IS NULL OR p.filial_id = ANY($5))
       ORDER BY
         nivel_score DESC,
         COALESCE(p.venda_media_diaria_60d, 0) DESC,
         p.descricao ASC
       LIMIT $6 OFFSET $7
     ),
     departamentos_hierarquia AS (
       SELECT DISTINCT departamento_id, departamento_nome
       FROM produtos_ruptura
     )
     SELECT COALESCE(
       (SELECT json_agg(
         json_build_object(
           ''departamento_id'', d.departamento_id,
           ''departamento_nome'', d.departamento_nome,
           ''produtos'', (
             SELECT COALESCE(json_agg(
               json_build_object(
                 ''produto_id'', pr.produto_id,
                 ''filial_id'', pr.filial_id,
                 ''filial_nome'', pr.filial_nome,
                 ''produto_descricao'', pr.produto_nome,
                 ''estoque_atual'', pr.estoque_atual,
                 ''curva_venda'', pr.curva_abcd,
                 ''dias_com_venda_60d'', pr.dias_com_venda_60d,
                 ''dias_com_venda_ultimos_3d'', pr.dias_com_venda_ultimos_3d,
                 ''venda_media_diaria_60d'', pr.venda_media_diaria_60d,
                 ''valor_estoque_parado'', pr.valor_estoque_parado,
                 ''nivel_ruptura'', pr.nivel_ruptura
               )
               ORDER BY pr.nivel_score DESC, pr.venda_media_diaria_60d DESC, pr.produto_nome
             ), ''[]''::json)
             FROM produtos_ruptura pr
             WHERE pr.departamento_id = d.departamento_id
           )
         )
         ORDER BY
           CASE WHEN upper(d.departamento_nome) LIKE ''%SEM DEPARTAMENTO%'' THEN 1 ELSE 0 END,
           d.departamento_nome
       )
       FROM departamentos_hierarquia d),
       ''[]''::json
     )';

  EXECUTE v_query INTO v_result
    USING p_limite_minimo_dias, p_curvas, v_departamento_filter_ids, p_busca, p_filiais, p_page_size, v_offset;

  RETURN QUERY SELECT COALESCE(v_total_records, 0), p_page, p_page_size, v_total_pages, v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_sales_by_month_chart(schema_name text, p_filiais text, p_data_inicio date, p_data_fim date, p_filter_type text)
RETURNS json
LANGUAGE plpgsql
AS $function$
DECLARE
  result json;
  filial_filter text := '';
  v_filter_type text := coalesce(p_filter_type, 'year');
  v_start date;
  v_end date;
  v_prev_start date;
  v_prev_end date;
BEGIN
  IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
    v_start := make_date(extract(year from current_date)::int, 1, 1);
    v_end := make_date(extract(year from current_date)::int, 12, 31);
    v_filter_type := 'year';
  ELSE
    IF v_filter_type = 'year' THEN
      v_start := make_date(extract(year from p_data_inicio)::int, 1, 1);
      v_end := make_date(extract(year from p_data_inicio)::int, 12, 31);
    ELSIF v_filter_type = 'month' THEN
      v_start := p_data_inicio;
      v_end := p_data_fim;
    ELSE
      v_start := date_trunc('month', p_data_inicio)::date;
      v_end := (date_trunc('month', p_data_fim) + interval '1 month - 1 day')::date;
    END IF;
  END IF;

  v_prev_start := (v_start - interval '1 year')::date;
  v_prev_end := (v_end - interval '1 year')::date;

  IF p_filiais IS NOT NULL AND p_filiais != 'all' AND p_filiais != '' THEN
    filial_filter := format('and filial_id in (%s)', p_filiais);
  END IF;

  EXECUTE format($q$
    with
    periods as (
      select
        gs::date as period_date,
        case
          when $1 = 'month' then to_char(gs, 'DD')
          when $1 = 'custom' then (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int] || '/' || extract(year from gs)::int
          else (array['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'])[extract(month from gs)::int]
        end as mes
      from generate_series(
        $2::date,
        $3::date,
        case when $1 = 'month' then interval '1 day' else interval '1 month' end
      ) gs
    ),
    sales_current as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_venda)::date as period_date,
        sum(valor_total) as total_vendas
      from %I.vendas_diarias_por_filial
      where data_venda between $2 and $3
      %s
      group by 1
    ),
    sales_prev as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_venda)::date as period_date,
        sum(valor_total) as total_vendas
      from %I.vendas_diarias_por_filial
      where data_venda between $4 and $5
      %s
      group by 1
    ),
    descontos_current as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_desconto)::date as period_date,
        sum(valor_desconto) as total_descontos
      from %I.descontos_venda
      where data_desconto between $2 and $3
      %s
      group by 1
    ),
    descontos_prev as (
      select
        date_trunc(case when $1 = 'month' then 'day' else 'month' end, data_desconto)::date as period_date,
        sum(valor_desconto) as total_descontos
      from %I.descontos_venda
      where data_desconto between $4 and $5
      %s
      group by 1
    )
    select json_agg(t)
    from (
      select
        p.mes,
        (coalesce(sc.total_vendas, 0) - coalesce(dc.total_descontos, 0))::numeric(15,2) as total_vendas,
        (coalesce(sp.total_vendas, 0) - coalesce(dp.total_descontos, 0))::numeric(15,2) as total_vendas_ano_anterior
      from periods p
      left join sales_current sc on sc.period_date = p.period_date
      left join descontos_current dc on dc.period_date = p.period_date
      left join sales_prev sp on sp.period_date = (p.period_date - interval '1 year')::date
      left join descontos_prev dp on dp.period_date = (p.period_date - interval '1 year')::date
      order by p.period_date
    ) t
  $q$,
    schema_name, filial_filter,
    schema_name, filial_filter,
    schema_name, filial_filter,
    schema_name, filial_filter
  )
  INTO result
  USING v_filter_type, v_start, v_end, v_prev_start, v_prev_end;

  RETURN COALESCE(result, '[]'::json);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_setores_com_nivel1(p_schema text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout TO '30s'
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  EXECUTE format('
    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        ''id'', s.id,
        ''nome'', s.nome,
        ''departamento_nivel'', s.departamento_nivel,
        ''departamento_ids'', s.departamento_ids,
        ''ativo'', s.ativo,
        ''departamento_ids_nivel_1'', (
          SELECT COALESCE(ARRAY_AGG(DISTINCT dl1.departamento_id), ARRAY[]::bigint[])
          FROM %I.departments_level_1 dl1
          WHERE
            (s.departamento_nivel = 1 AND dl1.departamento_id = ANY(s.departamento_ids))
            OR (s.departamento_nivel = 2 AND dl1.pai_level_2_id = ANY(s.departamento_ids))
            OR (s.departamento_nivel = 3 AND dl1.pai_level_3_id = ANY(s.departamento_ids))
            OR (s.departamento_nivel = 4 AND dl1.pai_level_4_id = ANY(s.departamento_ids))
            OR (s.departamento_nivel = 5 AND dl1.pai_level_5_id = ANY(s.departamento_ids))
            OR (s.departamento_nivel = 6 AND dl1.pai_level_6_id = ANY(s.departamento_ids))
        )
      )
    ORDER BY s.nome), ''[]''::jsonb)
    FROM %I.setores s
    WHERE s.ativo = true
  ', p_schema, p_schema)
  INTO v_result;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_total_sku_distinct(p_schema text, p_data_inicio date, p_data_fim date, p_filiais text DEFAULT 'all'::text)
RETURNS TABLE(total_sku bigint)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_filiais_condition TEXT;
BEGIN
  IF p_filiais IS NULL OR p_filiais = 'all' OR p_filiais = '' THEN
    v_filiais_condition := '1=1';
  ELSE
    v_filiais_condition := 'filial_id IN (' || p_filiais || ')';
  END IF;

  RETURN QUERY EXECUTE format('
    SELECT
      COUNT(DISTINCT id_produto)::BIGINT as total_sku
    FROM %I.vendas
    WHERE data_venda BETWEEN $1 AND $2
      AND %s
  ', p_schema, v_filiais_condition)
  USING p_data_inicio, p_data_fim;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_total_sku_distinct_pa(
  p_schema text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais text DEFAULT 'all'::text,
  p_filter_type text DEFAULT 'year'::text
)
RETURNS TABLE(pa_total_sku bigint)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_pa_data_inicio DATE;
  v_pa_data_fim DATE;
  v_filiais_condition TEXT;
BEGIN
  IF p_filter_type = 'month' THEN
    v_pa_data_inicio := p_data_inicio - INTERVAL '1 year';
    v_pa_data_fim := p_data_fim - INTERVAL '1 year';
  ELSIF p_filter_type = 'year' THEN
    v_pa_data_inicio := p_data_inicio - INTERVAL '1 year';
    v_pa_data_fim := p_data_fim - INTERVAL '1 year';
  ELSE
    v_pa_data_inicio := p_data_inicio - (p_data_fim - p_data_inicio + 1);
    v_pa_data_fim := p_data_inicio - INTERVAL '1 day';
  END IF;

  IF p_filiais IS NULL OR p_filiais = 'all' OR p_filiais = '' THEN
    v_filiais_condition := '1=1';
  ELSE
    v_filiais_condition := 'filial_id IN (' || p_filiais || ')';
  END IF;

  RETURN QUERY EXECUTE format('
    SELECT
      COUNT(DISTINCT id_produto)::BIGINT as pa_total_sku
    FROM %I.vendas
    WHERE data_venda BETWEEN $1 AND $2
      AND %s
  ', p_schema, v_filiais_condition)
  USING v_pa_data_inicio, v_pa_data_fim;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_user_authorized_branch_ids(p_user_id uuid)
RETURNS uuid[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_branch_ids UUID[];
BEGIN
  SELECT ARRAY_AGG(branch_id)
  INTO v_branch_ids
  FROM public.user_authorized_branches
  WHERE user_id = p_user_id;

  RETURN COALESCE(v_branch_ids, ARRAY[]::UUID[]);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_venda_curva_report(
  p_schema text,
  p_mes integer,
  p_ano integer,
  p_filial_id bigint DEFAULT NULL::bigint,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50,
  p_data_fim_override date DEFAULT NULL::date
)
RETURNS TABLE(
  dept_nivel3 text,
  dept_nivel2 text,
  dept_nivel1 text,
  produto_codigo bigint,
  produto_descricao text,
  filial_id bigint,
  qtde numeric,
  valor_vendas numeric,
  valor_lucro numeric,
  percentual_lucro numeric,
  curva_venda text,
  curva_lucro text
)
LANGUAGE plpgsql
AS $function$
DECLARE
  v_offset integer;
  v_data_inicio date;
  v_data_fim date;
BEGIN
  v_offset := (p_page - 1) * p_page_size;

  v_data_inicio := make_date(p_ano, p_mes, 1);
  v_data_fim := coalesce(p_data_fim_override, (v_data_inicio + interval '1 month')::date);

  RETURN QUERY EXECUTE format('
    WITH vendas_agregadas AS (
      SELECT
        COALESCE(d3.descricao, ''Sem Nível 3'') as dept3_nome,
        COALESCE(d2.descricao, ''Sem Nível 2'') as dept2_nome,
        d1.descricao as dept1_nome,
        p.id as produto_id,
        p.descricao as produto_nome,
        v.filial_id,
        COALESCE(p.curva_abcd, ''D'') as curva_venda,
        COALESCE(p.curva_lucro, ''D'') as curva_lucro,
        SUM(v.quantidade) as total_qtde,
        SUM(v.valor_vendas) as total_valor_vendas,
        SUM(COALESCE(v.valor_vendas, 0) - (COALESCE(v.custo_compra, 0) * COALESCE(v.quantidade, 0))) as total_lucro
      FROM %I.vendas v
      INNER JOIN %I.produtos p
        ON p.id = v.id_produto
        AND p.filial_id = v.filial_id
        AND p.ativo = true
      INNER JOIN %I.departments_level_1 d1
        ON d1.departamento_id = p.departamento_id
      LEFT JOIN %I.departments_level_2 d2
        ON d2.departamento_id = d1.pai_level_2_id
      LEFT JOIN %I.departments_level_3 d3
        ON d3.departamento_id = d1.pai_level_3_id
      WHERE v.data_venda >= $1
        AND v.data_venda < $2
        AND v.valor_vendas > 0
        AND ($3 IS NULL OR v.filial_id = $3)
      GROUP BY
        d3.descricao,
        d2.descricao,
        d1.descricao,
        p.id,
        p.descricao,
        v.filial_id,
        p.curva_abcd,
        p.curva_lucro
    ),
    dept3_totais AS (
      SELECT
        dept3_nome,
        SUM(total_valor_vendas) as total_vendas
      FROM vendas_agregadas
      GROUP BY dept3_nome
      ORDER BY total_vendas DESC
      LIMIT $4 OFFSET $5
    )
    SELECT
      va.dept3_nome::text,
      va.dept2_nome::text,
      va.dept1_nome::text,
      va.produto_id,
      va.produto_nome::text,
      va.filial_id,
      ROUND(va.total_qtde::numeric, 2),
      ROUND(va.total_valor_vendas::numeric, 2),
      ROUND(va.total_lucro::numeric, 2),
      CASE
        WHEN va.total_valor_vendas > 0
        THEN ROUND((va.total_lucro / va.total_valor_vendas) * 100, 2)
        ELSE 0
      END as percentual_lucro,
      va.curva_venda::text,
      va.curva_lucro::text
    FROM vendas_agregadas va
    INNER JOIN dept3_totais dt ON va.dept3_nome = dt.dept3_nome
    ORDER BY
      va.dept3_nome,
      va.dept2_nome,
      va.dept1_nome,
      CASE va.curva_venda
        WHEN ''A'' THEN 1
        WHEN ''B'' THEN 2
        WHEN ''C'' THEN 3
        WHEN ''D'' THEN 4
        ELSE 5
      END,
      va.total_valor_vendas DESC
  ', p_schema, p_schema, p_schema, p_schema, p_schema)
  USING v_data_inicio, v_data_fim, p_filial_id, p_page_size, v_offset;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_vendas_por_filial(
  p_schema text,
  p_data_inicio date,
  p_data_fim date,
  p_filiais text DEFAULT 'all'::text,
  p_filter_type text DEFAULT 'year'::text
)
RETURNS TABLE(
  filial_id bigint,
  valor_total numeric,
  custo_total numeric,
  total_lucro numeric,
  quantidade_total numeric,
  total_transacoes numeric,
  ticket_medio numeric,
  margem_lucro numeric,
  pa_valor_total numeric,
  pa_custo_total numeric,
  pa_total_lucro numeric,
  pa_total_transacoes numeric,
  pa_ticket_medio numeric,
  pa_margem_lucro numeric,
  delta_valor numeric,
  delta_valor_percent numeric,
  delta_custo numeric,
  delta_custo_percent numeric,
  delta_lucro numeric,
  delta_lucro_percent numeric,
  delta_margem numeric,
  total_entradas numeric,
  pa_total_entradas numeric,
  delta_entradas numeric,
  delta_entradas_percent numeric,
  total_cupons bigint,
  pa_total_cupons bigint,
  delta_cupons bigint,
  delta_cupons_percent numeric,
  total_sku bigint,
  pa_total_sku bigint,
  delta_sku bigint,
  delta_sku_percent numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_pa_data_inicio DATE;
  v_pa_data_fim DATE;
  v_filiais_array BIGINT[];
BEGIN
  IF p_filter_type = 'month' THEN
    v_pa_data_inicio := p_data_inicio - INTERVAL '1 year';
    v_pa_data_fim := p_data_fim - INTERVAL '1 year';
  ELSIF p_filter_type = 'year' THEN
    v_pa_data_inicio := p_data_inicio - INTERVAL '1 year';
    v_pa_data_fim := p_data_fim - INTERVAL '1 year';
  ELSE
    v_pa_data_inicio := p_data_inicio - (p_data_fim - p_data_inicio + 1);
    v_pa_data_fim := p_data_inicio - INTERVAL '1 day';
  END IF;

  IF p_filiais IS NOT NULL AND p_filiais != 'all' AND p_filiais != '' THEN
    v_filiais_array := string_to_array(p_filiais, ',')::BIGINT[];
  ELSE
    v_filiais_array := NULL;
  END IF;

  RETURN QUERY EXECUTE format('
    WITH 
    periodo_atual AS (
      SELECT
        v.filial_id,
        SUM(v.valor_total) as valor_total_bruto,
        SUM(v.custo_total) as custo_total_bruto,
        SUM(v.total_lucro) as total_lucro_bruto,
        SUM(v.quantidade_total) as quantidade_total,
        SUM(v.total_transacoes)::NUMERIC as total_transacoes
      FROM %I.vendas_diarias_por_filial v
      WHERE v.data_venda BETWEEN $1 AND $2
        AND ($7::BIGINT[] IS NULL OR v.filial_id = ANY($7))
      GROUP BY v.filial_id
    ),
    descontos_periodo_atual AS (
      SELECT
        d.filial_id,
        COALESCE(SUM(d.valor_desconto), 0) as total_desconto_venda,
        COALESCE(SUM(d.desconto_custo), 0) as total_desconto_custo
      FROM %I.descontos_venda d
      WHERE d.data_desconto BETWEEN $1 AND $2
        AND ($7::BIGINT[] IS NULL OR d.filial_id = ANY($7))
      GROUP BY d.filial_id
    ),
    entradas_periodo_atual AS (
      SELECT
        e.filial_id,
        COALESCE(SUM(e.valor_total), 0) as total_entradas
      FROM %I.entradas e
      WHERE e.transacao IN (''P'', ''V'')
        AND e.data_entrada BETWEEN $1 AND $2
        AND ($7::BIGINT[] IS NULL OR e.filial_id = ANY($7))
      GROUP BY e.filial_id
    ),
    cupons_periodo_atual AS (
      SELECT
        r.filial_id,
        COALESCE(SUM(r.qtde_cupons), 0) as total_cupons
      FROM %I.resumo_vendas_caixa r
      WHERE r.data BETWEEN $1 AND $2
        AND ($7::BIGINT[] IS NULL OR r.filial_id = ANY($7))
      GROUP BY r.filial_id
    ),
    sku_periodo_atual AS (
      SELECT
        v.filial_id,
        COUNT(DISTINCT v.id_produto) as total_sku
      FROM %I.vendas v
      WHERE v.data_venda BETWEEN $1 AND $2
        AND ($7::BIGINT[] IS NULL OR v.filial_id = ANY($7))
      GROUP BY v.filial_id
    ),
    periodo_atual_com_desconto AS (
      SELECT
        pa.filial_id,
        pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0) as valor_total,
        pa.custo_total_bruto - COALESCE(dpa.total_desconto_custo, 0) as custo_total,
        (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) -
        (pa.custo_total_bruto - COALESCE(dpa.total_desconto_custo, 0)) as total_lucro,
        pa.quantidade_total,
        pa.total_transacoes,
        CASE
          WHEN pa.total_transacoes > 0
          THEN (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) / pa.total_transacoes
          ELSE 0
        END as ticket_medio,
        CASE
          WHEN (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) > 0
          THEN (((pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) -
                 (pa.custo_total_bruto - COALESCE(dpa.total_desconto_custo, 0)))::NUMERIC /
                (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) * 100)
          ELSE 0
        END as margem_lucro
      FROM periodo_atual pa
      LEFT JOIN descontos_periodo_atual dpa ON pa.filial_id = dpa.filial_id
    ),
    periodo_anterior AS (
      SELECT
        v.filial_id,
        SUM(v.valor_total) as valor_total_bruto,
        SUM(v.custo_total) as custo_total_bruto,
        SUM(v.total_lucro) as total_lucro_bruto,
        SUM(v.total_transacoes)::NUMERIC as total_transacoes
      FROM %I.vendas_diarias_por_filial v
      WHERE v.data_venda BETWEEN $3 AND $4
        AND ($7::BIGINT[] IS NULL OR v.filial_id = ANY($7))
      GROUP BY v.filial_id
    ),
    descontos_periodo_anterior AS (
      SELECT
        d.filial_id,
        COALESCE(SUM(d.valor_desconto), 0) as total_desconto_venda,
        COALESCE(SUM(d.desconto_custo), 0) as total_desconto_custo
      FROM %I.descontos_venda d
      WHERE d.data_desconto BETWEEN $3 AND $4
        AND ($7::BIGINT[] IS NULL OR d.filial_id = ANY($7))
      GROUP BY d.filial_id
    ),
    entradas_periodo_anterior AS (
      SELECT
        e.filial_id,
        COALESCE(SUM(e.valor_total), 0) as pa_total_entradas
      FROM %I.entradas e
      WHERE e.transacao IN (''P'', ''V'')
        AND e.data_entrada BETWEEN $3 AND $4
        AND ($7::BIGINT[] IS NULL OR e.filial_id = ANY($7))
      GROUP BY e.filial_id
    ),
    cupons_periodo_anterior AS (
      SELECT
        r.filial_id,
        COALESCE(SUM(r.qtde_cupons), 0) as pa_total_cupons
      FROM %I.resumo_vendas_caixa r
      WHERE r.data BETWEEN $3 AND $4
        AND ($7::BIGINT[] IS NULL OR r.filial_id = ANY($7))
      GROUP BY r.filial_id
    ),
    sku_periodo_anterior AS (
      SELECT
        v.filial_id,
        COUNT(DISTINCT v.id_produto) as pa_total_sku
      FROM %I.vendas v
      WHERE v.data_venda BETWEEN $3 AND $4
        AND ($7::BIGINT[] IS NULL OR v.filial_id = ANY($7))
      GROUP BY v.filial_id
    ),
    periodo_anterior_com_desconto AS (
      SELECT
        pa.filial_id,
        pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0) as pa_valor_total,
        pa.custo_total_bruto - COALESCE(dpa.total_desconto_custo, 0) as pa_custo_total,
        (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) -
        (pa.custo_total_bruto - COALESCE(dpa.total_desconto_custo, 0)) as pa_total_lucro,
        pa.total_transacoes as pa_total_transacoes,
        CASE
          WHEN pa.total_transacoes > 0
          THEN (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) / pa.total_transacoes
          ELSE 0
        END as pa_ticket_medio,
        CASE
          WHEN (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) > 0
          THEN (((pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) -
                 (pa.custo_total_bruto - COALESCE(dpa.total_desconto_custo, 0)))::NUMERIC /
                (pa.valor_total_bruto - COALESCE(dpa.total_desconto_venda, 0)) * 100)
          ELSE 0
        END as pa_margem_lucro
      FROM periodo_anterior pa
      LEFT JOIN descontos_periodo_anterior dpa ON pa.filial_id = dpa.filial_id
    ),
    todas_filiais AS (
      SELECT DISTINCT filial_id FROM periodo_atual_com_desconto
      UNION
      SELECT DISTINCT filial_id FROM periodo_anterior_com_desconto
      UNION
      SELECT DISTINCT filial_id FROM entradas_periodo_atual
      UNION
      SELECT DISTINCT filial_id FROM entradas_periodo_anterior
      UNION
      SELECT DISTINCT filial_id FROM cupons_periodo_atual
      UNION
      SELECT DISTINCT filial_id FROM cupons_periodo_anterior
      UNION
      SELECT DISTINCT filial_id FROM sku_periodo_atual
      UNION
      SELECT DISTINCT filial_id FROM sku_periodo_anterior
    )
    SELECT
      tf.filial_id as filial_id,
      COALESCE(pc.valor_total, 0)::NUMERIC(15,2) as valor_total,
      COALESCE(pc.custo_total, 0)::NUMERIC(15,2) as custo_total,
      COALESCE(pc.total_lucro, 0)::NUMERIC(15,2) as total_lucro,
      COALESCE(pc.quantidade_total, 0)::NUMERIC(15,2) as quantidade_total,
      COALESCE(pc.total_transacoes, 0)::NUMERIC as total_transacoes,
      COALESCE(pc.ticket_medio, 0)::NUMERIC(15,2) as ticket_medio,
      COALESCE(pc.margem_lucro, 0)::NUMERIC(10,2) as margem_lucro,
      COALESCE(pa.pa_valor_total, 0)::NUMERIC(15,2) as pa_valor_total,
      COALESCE(pa.pa_custo_total, 0)::NUMERIC(15,2) as pa_custo_total,
      COALESCE(pa.pa_total_lucro, 0)::NUMERIC(15,2) as pa_total_lucro,
      COALESCE(pa.pa_total_transacoes, 0)::NUMERIC as pa_total_transacoes,
      COALESCE(pa.pa_ticket_medio, 0)::NUMERIC(15,2) as pa_ticket_medio,
      COALESCE(pa.pa_margem_lucro, 0)::NUMERIC(10,2) as pa_margem_lucro,
      (COALESCE(pc.valor_total, 0) - COALESCE(pa.pa_valor_total, 0))::NUMERIC(15,2) as delta_valor,
      CASE
        WHEN COALESCE(pa.pa_valor_total, 0) > 0
        THEN LEAST(((COALESCE(pc.valor_total, 0) - COALESCE(pa.pa_valor_total, 0)) / pa.pa_valor_total * 100), 99999999.99)::NUMERIC(10,2)
        ELSE 0
      END as delta_valor_percent,
      (COALESCE(pc.custo_total, 0) - COALESCE(pa.pa_custo_total, 0))::NUMERIC(15,2) as delta_custo,
      CASE
        WHEN COALESCE(pa.pa_custo_total, 0) > 0
        THEN LEAST(((COALESCE(pc.custo_total, 0) - COALESCE(pa.pa_custo_total, 0)) / pa.pa_custo_total * 100), 99999999.99)::NUMERIC(10,2)
        ELSE 0
      END as delta_custo_percent,
      (COALESCE(pc.total_lucro, 0) - COALESCE(pa.pa_total_lucro, 0))::NUMERIC(15,2) as delta_lucro,
      CASE
        WHEN COALESCE(pa.pa_total_lucro, 0) > 0
        THEN LEAST(((COALESCE(pc.total_lucro, 0) - COALESCE(pa.pa_total_lucro, 0)) / pa.pa_total_lucro * 100), 99999999.99)::NUMERIC(10,2)
        ELSE 0
      END as delta_lucro_percent,
      (COALESCE(pc.margem_lucro, 0) - COALESCE(pa.pa_margem_lucro, 0))::NUMERIC(10,2) as delta_margem,
      COALESCE(epa.total_entradas, 0)::NUMERIC(15,2) as total_entradas,
      COALESCE(epan.pa_total_entradas, 0)::NUMERIC(15,2) as pa_total_entradas,
      (COALESCE(epa.total_entradas, 0) - COALESCE(epan.pa_total_entradas, 0))::NUMERIC(15,2) as delta_entradas,
      CASE
        WHEN COALESCE(epan.pa_total_entradas, 0) > 0
        THEN LEAST(((COALESCE(epa.total_entradas, 0) - COALESCE(epan.pa_total_entradas, 0)) / epan.pa_total_entradas * 100), 99999999.99)::NUMERIC(10,2)
        ELSE 0
      END as delta_entradas_percent,
      COALESCE(cpa.total_cupons, 0)::BIGINT as total_cupons,
      COALESCE(cpan.pa_total_cupons, 0)::BIGINT as pa_total_cupons,
      (COALESCE(cpa.total_cupons, 0) - COALESCE(cpan.pa_total_cupons, 0))::BIGINT as delta_cupons,
      CASE
        WHEN COALESCE(cpan.pa_total_cupons, 0) > 0
        THEN LEAST(((COALESCE(cpa.total_cupons, 0) - COALESCE(cpan.pa_total_cupons, 0))::NUMERIC / cpan.pa_total_cupons * 100), 99999999.99)::NUMERIC(10,2)
        ELSE 0
      END as delta_cupons_percent,
      COALESCE(spa.total_sku, 0)::BIGINT as total_sku,
      COALESCE(span.pa_total_sku, 0)::BIGINT as pa_total_sku,
      (COALESCE(spa.total_sku, 0) - COALESCE(span.pa_total_sku, 0))::BIGINT as delta_sku,
      CASE
        WHEN COALESCE(span.pa_total_sku, 0) > 0
        THEN LEAST(((COALESCE(spa.total_sku, 0) - COALESCE(span.pa_total_sku, 0))::NUMERIC / span.pa_total_sku * 100), 99999999.99)::NUMERIC(10,2)
        ELSE 0
      END as delta_sku_percent
    FROM todas_filiais tf
    LEFT JOIN periodo_atual_com_desconto pc ON tf.filial_id = pc.filial_id
    LEFT JOIN periodo_anterior_com_desconto pa ON tf.filial_id = pa.filial_id
    LEFT JOIN entradas_periodo_atual epa ON tf.filial_id = epa.filial_id
    LEFT JOIN entradas_periodo_anterior epan ON tf.filial_id = epan.filial_id
    LEFT JOIN cupons_periodo_atual cpa ON tf.filial_id = cpa.filial_id
    LEFT JOIN cupons_periodo_anterior cpan ON tf.filial_id = cpan.filial_id
    LEFT JOIN sku_periodo_atual spa ON tf.filial_id = spa.filial_id
    LEFT JOIN sku_periodo_anterior span ON tf.filial_id = span.filial_id
    WHERE COALESCE(pc.valor_total, 0) > 0 
       OR COALESCE(epa.total_entradas, 0) > 0
       OR COALESCE(cpa.total_cupons, 0) > 0
       OR COALESCE(spa.total_sku, 0) > 0
    ORDER BY COALESCE(pc.valor_total, 0) DESC NULLS LAST
  ',
  p_schema, p_schema, p_schema, p_schema, p_schema,
  p_schema, p_schema, p_schema, p_schema, p_schema
  )
  USING p_data_inicio, p_data_fim, v_pa_data_inicio, v_pa_data_fim, NULL, NULL, v_filiais_array;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $function$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $function$;

CREATE OR REPLACE FUNCTION public.insert_audit_log(
  p_module text,
  p_sub_module text DEFAULT NULL::text,
  p_tenant_id uuid DEFAULT NULL::uuid,
  p_action text DEFAULT 'access'::text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_log_id uuid;
BEGIN
  INSERT INTO public.audit_logs (
    user_id,
    tenant_id,
    module,
    sub_module,
    action,
    metadata,
    created_at
  ) VALUES (
    auth.uid(),
    p_tenant_id,
    p_module,
    p_sub_module,
    p_action,
    p_metadata,
    NOW() AT TIME ZONE 'America/Sao_Paulo'
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.insert_audit_log(
  p_module text,
  p_sub_module text DEFAULT NULL::text,
  p_tenant_id uuid DEFAULT NULL::uuid,
  p_user_name text DEFAULT NULL::text,
  p_user_email text DEFAULT NULL::text,
  p_action text DEFAULT 'access'::text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_log_id uuid;
BEGIN
  INSERT INTO public.audit_logs (
    user_id,
    user_name,
    user_email,
    tenant_id,
    module,
    sub_module,
    action,
    metadata,
    created_at
  ) VALUES (
    auth.uid(),
    p_user_name,
    p_user_email,
    p_tenant_id,
    p_module,
    p_sub_module,
    p_action,
    p_metadata,
    NOW() AT TIME ZONE 'America/Sao_Paulo'
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.insert_desconto_venda(
  p_schema text,
  p_filial_id integer,
  p_data_desconto date,
  p_valor_desconto numeric,
  p_observacao text DEFAULT NULL::text,
  p_created_by uuid DEFAULT NULL::uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result json;
  v_new_id uuid;
BEGIN
  IF p_valor_desconto < 0 THEN
    RAISE EXCEPTION 'Valor do desconto deve ser maior ou igual a zero';
  END IF;

  v_new_id := gen_random_uuid();

  EXECUTE format('
    INSERT INTO %I.descontos_venda (
      id, filial_id, data_desconto, valor_desconto, observacao, created_by
    )
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING json_build_object(
      ''id'', id,
      ''filial_id'', filial_id,
      ''data_desconto'', data_desconto,
      ''valor_desconto'', valor_desconto,
      ''observacao'', observacao,
      ''created_at'', created_at,
      ''updated_at'', updated_at,
      ''created_by'', created_by
    )
  ', p_schema)
  USING v_new_id, p_filial_id, p_data_desconto, p_valor_desconto, p_observacao, p_created_by
  INTO v_result;

  RETURN v_result;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Já existe um desconto lançado para esta filial nesta data';
END;
$function$;

CREATE OR REPLACE FUNCTION public.insert_desconto_venda(
  p_schema text,
  p_filial_id integer,
  p_data_desconto date,
  p_valor_desconto numeric,
  p_desconto_custo numeric,
  p_observacao text DEFAULT NULL::text,
  p_created_by uuid DEFAULT NULL::uuid
)
RETURNS TABLE(
  id uuid,
  filial_id integer,
  data_desconto date,
  valor_desconto numeric,
  desconto_custo numeric,
  observacao text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_id uuid;
BEGIN
  v_id := gen_random_uuid();

  EXECUTE format(
    'INSERT INTO %I.descontos_venda (
      id, filial_id, data_desconto, valor_desconto, desconto_custo, observacao, created_by, created_at, updated_at
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, NOW(), NOW()
    )',
    p_schema
  ) USING v_id, p_filial_id, p_data_desconto, p_valor_desconto, p_desconto_custo, p_observacao, p_created_by;

  RETURN QUERY EXECUTE format(
    'SELECT 
      id, filial_id, data_desconto, valor_desconto, desconto_custo, observacao, created_at, updated_at
    FROM %I.descontos_venda
    WHERE id = $1',
    p_schema
  ) USING v_id;
END;
$function$;
