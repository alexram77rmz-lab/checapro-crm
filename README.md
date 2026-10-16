# ⏱️ ChecaPro CRM | Sistema Híbrido de Checadores, Tablas de Retardos, Alertas al Empleado y CRM Multi-Empresa

Sistema integral Web + PWA diseñado tanto para **empresas con múltiples sucursales** como para el **beneficio directo del empleado**.

## 🚀 ¿Qué incluye el sistema?

1. **📊 Tablas de Empresa y Retardos en Tiempo Real (`Vista 1`)**:
   - Control centralizado de quién llegó a tiempo, quién llegó tarde (con cálculo exacto de minutos de retardo según su turno y tolerancia), quién salió a comer, quién regresó de comer y quién no ha checado.
   - Filtros rápidos: `Todos`, `🚨 Llegaron Tarde`, `⚠️ No han checado`, `🍽️ Salida a Comer`, `✅ A Tiempo`, `💬 Con Respuesta del Empleado`.
   - Exportación directa a **Excel (CSV)** con 1 clic.

2. **📱 Portal y App del Empleado (`Vista 2` - Por qué le conviene al empleado)**:
   - **Checador Híbrido en Vivo**: Botones para registrar **1. Entrada**, **2. Salida a Comer**, **3. Regreso de Comer**, **4. Salida de Turno** y **5. Movimientos Especiales** (*Comisión con cliente, Banco, Pausa Médica, Home Office*).
   - **🔔 Alerta Interactiva "¿Por qué no checaste?"**: Cuando el empleado olvida checar o llega tarde, recibe una alerta inmediata en su App y por WhatsApp con botones de respuesta rápida (*"Olvidé checar al entrar"*, *"Falla en lector de huella"*, *"Tráfico"*, *"Comisión"*) para justificar al instante y **proteger su Bono de Puntualidad**.
   - **📈 Gráfica Personal del Empleado**: Gráfica interactiva de sus últimos 7 días mostrando exactamente qué días llegó a tiempo (verde) y qué días llegó tarde con los minutos exactos (ámbar/rojo), además de su termómetro de Bono de Puntualidad.

3. **🏢 CRM Multi-Empresa y Multi-Sucursal (`Vista 3`)**:
   - Filtra y administra múltiples empresas clientes, cada una con sus propias sucursales, horarios de entrada, minutos de tolerancia, tiempos de comida y dispositivos biométricos vinculados.
   - Incluye modales funcionales para dar de alta **Nuevas Empresas**, **Nuevas Sucursales** y **Nuevos Empleados**.

4. **🔢 Terminal Kiosco de Sucursal (`Vista 4`)**:
   - Pantalla tipo tablet para recepción o entrada de sucursal donde el empleado ingresa su PIN de 4 dígitos y registra su movimiento en 2 segundos.

5. **🔌 Conector Biométrico Físico & Webhook API (`Vista 5`)**:
   - Simulador de relojes físicos (ZKTeco, Hikvision, Anviz) y endpoint `POST /api/webhook/biometric` en `server.js`.

## ▶️ Cómo ejecutarlo

- **Opción A (Directo en Navegador)**: Abre `index.html` en cualquier navegador (PC, Tablet o Celular).
- **Opción B (Servidor Local + API Biométrica)**:
  ```powershell
  node server.js
  ```
  Y abre `http://localhost:3080`.
