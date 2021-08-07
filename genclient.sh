openssl genrsa -out /opt/mongodb/cert-admin.key 4096
openssl req -new -key /opt/mongodb/cert-admin.key -out /opt/mongodb/cert-admin.csr  -extensions v3_ca
openssl x509 -req -days 1825 -in /opt/mongodb/cert-admin.csr -CA /opt/mongodb/CA.crt -CAkey /opt/mongodb/CA.key -set_serial 01 -out /opt/mongodb/cert-admin.crt
cat /opt/mongodb/cert-admin.key /opt/mongodb/cert-admin.crt > /opt/mongodb/cert-admin.pem
