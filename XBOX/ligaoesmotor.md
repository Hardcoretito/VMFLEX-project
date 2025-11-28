# Ligações para o Motor MR62-31 com Driver BTS7960 e Arduino

Este documento detalha as ligações necessárias entre o seu motor MR62-31, o driver de motor BTS7960, o Arduino (controlador) e a fonte de alimentação.

---

## Componentes Necessários:

*   **Motor:** MR62-31 (Motor DC)
*   **Driver de Motor:** BTS7960 43A
*   **Controlador:** Placa Arduino (ex: Arduino Nano 33 BLE)
*   **Fonte de Alimentação Externa:** Para o motor (tensão e corrente adequadas para o MR62-31, geralmente 12V, 24V, etc., dependendo do seu motor específico).
*   **Cabos de Conexão**

---

## Diagrama de Ligações (Passo a Passo):

### 1. Fonte de Alimentação Externa para o Driver BTS7960:

*   Conecte o **positivo (+) da fonte de alimentação externa** ao terminal **B+** do driver BTS7960.
*   Conecte o **negativo (-) da fonte de alimentação externa** ao terminal **B-** do driver BTS7960.

    *   **Importante:** Esta fonte de alimentação deve ser capaz de fornecer a tensão e corrente necessárias para o seu motor MR62-31. **NÃO** use a fonte de alimentação do Arduino para alimentar o motor diretamente, pois pode danificar o Arduino.

### 2. Motor MR62-31 para o Driver BTS7960:

*   Conecte um terminal do seu motor MR62-31 ao terminal **M+** do driver BTS7960.
*   Conecte o outro terminal do seu motor MR62-31 ao terminal **M-** do driver BTS7960.

    *   A polaridade aqui determinará o sentido "padrão" de rotação quando o driver for ativado. Se o motor girar no sentido oposto ao esperado, pode inverter estas duas ligações.

### 3. Arduino para o Driver BTS7960 (Controle):

*   **Alimentação Lógica do Driver:**
    *   Conecte o pino **VCC** do driver BTS7960 ao pino **5V** do seu Arduino.
    *   Conecte o pino **GND** do driver BTS7960 ao pino **GND** do seu Arduino.

*   **Pinos de Controle (conforme o código Arduino):**
    *   Pino **R_EN** do driver BTS7960 -> Pino digital **5** do Arduino.
    *   Pino **L_EN** do driver BTS7960 -> Pino digital **6** do Arduino.
    *   Pino **R_PWM** do driver BTS7960 -> Pino PWM **9** do Arduino.
    *   Pino **L_PWM** do driver BTS7960 -> Pino PWM **10** do Arduino.

    *   **Nota:** Certifique-se de que os pinos do Arduino usados para `R_PWM` e `L_PWM` são pinos com capacidade PWM (geralmente marcados com um `~` ao lado do número no Arduino).

---

## Resumo das Ligações:

| Componente | Pino | Conecta a | Pino |
| :--------- | :--- | :-------- | :--- |
| **Fonte Externa** | +    | **BTS7960** | B+   |
| **Fonte Externa** | -    | **BTS7960** | B-   |
| **MR62-31** | (Terminal 1) | **BTS7960** | M+   |
| **MR62-31** | (Terminal 2) | **BTS7960** | M-   |
| **Arduino** | 5V   | **BTS7960** | VCC  |
| **Arduino** | GND  | **BTS7960** | GND  |
| **Arduino** | 5    | **BTS7960** | R_EN |
| **Arduino** | 6    | **BTS7960** | L_EN |
| **Arduino** | 9 (PWM) | **BTS7960** | R_PWM |
| **Arduino** | 10 (PWM) | **BTS7960** | L_PWM |

---

Com estas ligações e o código Arduino atualizado, você deverá ser capaz de controlar o seu motor MR62-31 com a sua aplicação iOS.
