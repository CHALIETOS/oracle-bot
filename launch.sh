#!/bin/bash

echo "Intentando crear instancia ARM..."

# Ejecutamos el comando OCI CLI capturando tanto la salida estándar como los errores
OUTPUT=$(oci compute instance launch \
  --availability-domain "fBUr:EU-MADRID-3-AD-1" \
  --compartment-id "ocid1.tenancy.oc1..aaaaaaaajebbtecducykqcazu2stjlqrgvd7k6flsbuyhi3usxg7psk4imfq" \
  --shape "VM.Standard.A1.Flex" \
  --shape-config '{"ocpus": 4, "memoryInGBs": 24}' \
  --subnet-id "ocid1.subnet.oc1.eu-madrid-3.aaaaaaaa7r4tznbmvkxpr53w63lt35ubjjpxpeisjtmdywnuuxa7vms6h72a" \
  --image-id "ocid1.image.oc1.eu-madrid-3.aaaaaaaaftiofoeugs6725ivdf2r4essef2zgkm34dm23m6h54kn2avogbwa" \
  --display-name "ubuntu-arm" \
  --metadata '{"ssh_authorized_keys": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGJEq8bIat47Lc0wlIdZVflexCmAPkhJGfIBXT7+ymHZguv3UrSHzZXsGb7vuZZV6hbZOvZP+k+8BHw7xncgCcENEMuAdHZPPrkbySbxT3jyABrBf1UCMmqE0hvTjYq89Qrp+F+AHiVA0GnuCwpEZxmSr7spTveIeBoayE6KIS47H2dNfTOtzsp1WuH7SYhkXkgcGzFVU+lWQ4YkKE2GCOqLyE97nmYdsiFk34kdnzmIqgxdCkjTFu6QFRjPBdODKHd7/abQ+45hibf7fFcIKDYQR63kbUcMpKO55lnnXYJVnWuJF1MGUjtb0QlWD60SXQrV78taPucyIzXP+cDLWH ssh-key-2026-05-24"}' \
  --assign-public-ip true 2>&1)

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "¡Instancia creada con éxito!"
    
    # Enviar notificación a Telegram
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="✅ *Oracle Cloud:* ¡La instancia ARM ha sido creada con éxito! Ve corriendo a comprobarlo en tu cuenta." \
        -d parse_mode="Markdown"
    
    exit 0
else
    echo "Fallo al crear la instancia. Detalles del error:"
    echo "$OUTPUT"
    
    if echo "$OUTPUT" | grep -q "Out of host capacity"; then
        echo "Error: No hay capacidad en los servidores de Oracle (Out of host capacity). GitHub Actions volverá a intentarlo en 15 minutos."
    elif echo "$OUTPUT" | grep -q "LimitExceeded"; then
        echo "Error: Límite excedido. Probablemente la instancia ya se ha creado o has alcanzado el límite de tu cuenta free tier."
    elif echo "$OUTPUT" | grep -q "NotAuthenticated"; then
        echo "Error: Fallo de autenticación. Revisa que los OCID y la Private Key en los secretos de GitHub estén correctos."
    else
        echo "Error desconocido."
    fi
    
    # Salimos con código 0 siempre para que el workflow aparezca en verde y GitHub no nos envíe un correo de error molesto cada 15 minutos.
    exit 0
fi
