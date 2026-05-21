CREATE DATABASE lab_ecommerce;
USE lab_ecommerce;

CREATE TABLE produtos (
id INT AUTO_INCREMENT PRIMARY KEY, 
nome VARCHAR(100),
preco DECIMAL(10,2),
estoque INT 

);

CREATE TABLE vendas (
id INT AUTO_INCREMENT PRIMARY KEY, 
produto_id INT,
quantidade INT,
total DECIMAL (10,2),
data_venda DATETIME DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

CREATE TABLE auditoria_precos (
id INT AUTO_INCREMENT PRIMARY KEY,
produto_id INT,
preco_antigo DECIMAL (10,2),
preco_novo DECIMAL (10,2),
data_alteracao DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO produtos (nome, preco, estoque) VALUES
('Notebook', 3500.00, 10),
('Smarthone', 2000.00, 20),
('Teclado Mecânico', 350.00, 15);

-- view
CREATE VIEW vw_produtos_disponiveis AS 
SELECT
	nome AS 'Produto',
	preco AS 'Valor',
    estoque AS 'Quantidade_Disponivel'
FROM produtos
WHERE estoque >0;


DELIMITER //

CREATE FUNCTION fn_calcular_desconto(valor DECIMAL(10,2), qtd INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
	DECLARE valor_final DECIMAL(10,2);
    
    IF qtd >= 3 THEN
		SET valor_final = (valor * qtd) * 0.90;
	ELSE
		SET valor_final = valor * qtd;
	END IF;
    
    RETURN valor_final;
END //

DELIMITER ;


DELIMITER //

CREATE TRIGGER trg_auditoria_preco
AFTER UPDATE ON produtos
FOR EACH ROW
BEGIN

	IF OLD.preco <> NEW.preco THEN
		INSERT INTO auditoria_precos (produto_id, preco_antigo, preco_novo)
        VALUES (OLD.id, OLD.preco, NEW.preco);
	END IF;
END//

DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_adicionar_estoque(IN p_produto_id INT, IN p_quantidade INT)
BEGIN
	UPDATE produtos
    SET estoque = estoque + p_quantidade
    WHERE id = p_produto_id;
    
    SELECT CONCAT('Estoque atualizado com sucesso. Foram adicionados ', p_quantiidade, 'itens') AS Mensagem;
    END //
    DELIMITER ;

CREATE TABLE mv_resumo_vendas (
	produto_nome VARCHAR(100),
    total_vendido DECIMAL(10,2),
    ultima_atualizacao DATETIME
);

DELIMITER //
CREATE PROCEDURE sp_refresh_mv_resumo_vendas()
BEGIN
	-- Limpa os dados antigos
	TRUNCATE TABLE mv_resumo_vendas;
    
    -- insere os dados processados pesados
    INSERT INTO mv_resumo_vendas (produto_nome, total_vendido, ultima_atualizacao)
    SELECT p.nome, SUM(v.total), CURRENT_TIMESTAMP
	FROM produtos p
    JOIN vendas v ON p.id= v.produto_id
    GROUP BY p.nome;
END //
DELIMITER ; 

-- criar um usuario ficticio para um analista
CREATE USER 'analista_dados'@'localhost' IDENTIFIED BY 'senha_segura_123';
-- liberar acesso (GRANT)apenas de leitura e apenas na view
GRANT SELECT ON lab_ecommerce.vw_produtos_disoniveis TO 'analista_dados'@'localhost';
-- 	atualizar privilégios
FLUSH PRIVILEGES;
-- se o analista mudar de cargo, você remove o acesso
REVOKE SELECT ON lab_ecommerce.vw_produtos_disponiveis FROM 'analista_dados'@'localhost';



