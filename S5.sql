--1 Crear cta bancaria
CREATE OR REPLACE PROCEDURE nueva_cuenta(
    var_cliente_id INT,
	var_numero_cta VARCHAR(20),
    var_tipo_cuenta VARCHAR(10),
    var_saldo_inicial NUMERIC(10, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO cuentas_bancarias (cliente_id, numero_cuenta, tipo_cuenta, saldo, fecha_apertura, estado)
    VALUES (var_cliente_id, var_numero_cta, var_tipo_cuenta, var_saldo_iniciaL, CURRENT_DATE, 'activa');
END;
$$;
CALL nueva_cuenta(1, '9087224567', 'ahorro', 42000);
SELECT * FROM cuentas_bancarias;

--2 Actualizar cliente
CREATE OR REPLACE PROCEDURE actualizar_cliente(
    var_cliente_id INT,
    var_direccion VARCHAR(100),
    var_telefono VARCHAR(20),
    var_correo_electronico VARCHAR(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM clientes WHERE cliente_id = var_cliente_id) THEN
        UPDATE clientes SET direccion = var_direccion, telefono = var_telefono, correo_electronico = var_correo_electronico WHERE cliente_id = var_cliente_id;
    ELSE
        RAISE EXCEPTION 'El cliente no existe';
    END IF;
END;
$$;
CALL actualizar_cliente(3, 'Circular de los sueños 101', '4770834', 'luismamartinez@example.com')
SELECT * FROM Clientes

--3 Eliminar cuenta
CREATE OR REPLACE PROCEDURE eliminar_cuenta(
    var_cuenta_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_id) THEN
		DELETE FROM clientes_transacciones WHERE transaccion_id IN (SELECT transaccion_id FROM transacciones WHERE cuenta_id = var_cuenta_id);
        DELETE FROM clientes_prestamos WHERE prestamo_id IN (SELECT prestamo_id FROM prestamos WHERE cuenta_id = var_cuenta_id);
		DELETE FROM clientes_tarjetas WHERE tarjeta_id IN (SELECT tarjeta_id FROM tarjetas_credito WHERE cuenta_id = var_cuenta_id);
		DELETE FROM clientes_cuentas WHERE cuenta_id = var_cuenta_id;
		DELETE FROM prestamos WHERE cuenta_id = var_cuenta_id;
        DELETE FROM tarjetas_credito WHERE cuenta_id = var_cuenta_id;
		DELETE FROM transacciones WHERE cuenta_id = var_cuenta_id;
        DELETE FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_id;     
    ELSE
        RAISE NOTICE 'La cuenta no existe';
    END IF;
END;
$$;
CALL eliminar_cuenta(2)
SELECT * FROM cuentas_bancarias

--4 Transferencia entre cuentas
CREATE OR REPLACE PROCEDURE realizar_transferencia(
    var_cuenta_origen INT,
    var_cuenta_destino INT,
    var_monto NUMERIC(10, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_origen) THEN
        RAISE EXCEPTION 'La cuenta de origen no existe';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_destino) THEN
        RAISE EXCEPTION 'La cuenta destino no existe';
    END IF;
    IF (SELECT saldo FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_origen) < var_monto THEN
        RAISE EXCEPTION 'Saldo insuficiente';
    END IF;
    UPDATE cuentas_bancarias SET saldo = saldo - var_monto WHERE cuenta_id = var_cuenta_origen;
	
    UPDATE cuentas_bancarias SET saldo = saldo + var_monto WHERE cuenta_id = var_cuenta_destino;

    INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	VALUES (var_cuenta_origen, 'transferencia', var_monto, CURRENT_TIMESTAMP, 'Se realiza transferencia a la cuenta');

    INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (var_cuenta_destino, 'transferencia', var_monto, CURRENT_TIMESTAMP, 'Se recibe transferencia desde la cuenta');
   END;
$$;
CALL realizar_transferencia(1,3,100)
SELECT * FROM transacciones

--5 Nueva trx
CREATE OR REPLACE PROCEDURE registrar_trx(
    var_cuenta_id INT,
    var_tipo_transaccion VARCHAR(15),
    var_monto NUMERIC(10, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_id) THEN
        RAISE EXCEPTION 'La cuenta no existe.';
    END IF;
    IF var_tipo_transaccion = 'depósito' THEN
        UPDATE cuentas_bancarias SET saldo = saldo + var_monto WHERE cuenta_id = var_cuenta_id;
    ELSIF var_tipo_transaccion = 'retiro' THEN
        IF (SELECT saldo FROM cuentas_bancarias WHERE cuenta_id = var_cuenta_id) < var_monto THEN
            RAISE EXCEPTION 'Saldo insuficiente en la cuenta';
        END IF;
        UPDATE cuentas_bancarias SET saldo = saldo - var_monto WHERE cuenta_id = var_cuenta_id;
    ELSE
        RAISE EXCEPTION 'No se puede realizar ya que solo se permite "depósito" o "retiro"';
    END IF;
    INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (var_cuenta_id, var_tipo_transaccion, var_monto, CURRENT_TIMESTAMP, 'Se realiza movimiento en la cuenta');
	END;
$$;
CALL registrar_trx(1, 'depósito', 100);
CALL registrar_trx(1, 'retiro', 50);
SELECT * FROM transacciones
SELECT * FROM cuentas_bancarias

--6 calcular saldo total
CREATE OR REPLACE FUNCTION calcular_total(
    var_cliente_id INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    var_saldo_total NUMERIC;
BEGIN
    SELECT SUM(saldo) INTO var_saldo_total FROM cuentas_bancarias WHERE cliente_id = var_cliente_id;
    RETURN var_saldo_total;
END;
$$;

SELECT calcular_total(1) AS saldo_total;

--7 Reporte trx por rango fechas
CREATE OR REPLACE FUNCTION reporte_trx_fechas(
    var_fecha_inicio DATE,
    var_fecha_fin DATE
)
RETURNS TABLE(
    cuenta_id INT,
    tipo_transaccion VARCHAR(15),
    monto NUMERIC(10, 2),
    fecha_transaccion TIMESTAMP,
    descripcion TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT t.cuenta_id, t.tipo_transaccion, t.monto, t.fecha_transaccion, t.descripcion
    FROM transacciones t WHERE t.fecha_transaccion BETWEEN var_fecha_inicio AND var_fecha_fin;
END;
$$;
SELECT * FROM reporte_trx_fechas('2023-01-01', '2024-08-30');




