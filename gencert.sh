mkdir -p certs
openssl genrsa -out /opt/mongodb/CA.key 4096
openssl req -new -x509 -days 1825 -key /opt/mongodb/CA.key -out /opt/mongodb/CA.crt
cat /opt/mongodb/CA.key /opt/mongodb/CA.crt > /opt/mongodb/CA.pem

openssl genrsa -out /opt/mongodb/certificate.key 4096
openssl req -new -key /opt/mongodb/certificate.key -out /opt/mongodb/certificate.csr
openssl x509 -req -days 1825 -in /opt/mongodb/certificate.csr -CA /opt/mongodb/CA.crt -CAkey /opt/mongodb/CA.key -set_serial 01 -out /opt/mongodb/certificate.crt
cat /opt/mongodb/certificate.key /opt/mongodb/certificate.crt > /opt/mongodb/certificate.pem

openssl genrsa -out /opt/mongodb/cert-admin.key 4096
openssl req -new -key /opt/mongodb/cert-admin.key -out /opt/mongodb/cert-admin.csr
openssl x509 -req -days 1825 -in /opt/mongodb/cert-admin.csr -CA /opt/mongodb/CA.crt -CAkey /opt/mongodb/CA.key -set_serial 01 -out /opt/mongodb/cert-admin.crt
cat /opt/mongodb/cert-admin.key /opt/mongodb/cert-admin.crt > /opt/mongodb/cert-admin.pem
