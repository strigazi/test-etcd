#!/bin/bash -xe

cert_dir=/srv/etcd
mkdir -p ${cert_dir}
cd ${cert_dir}

openssl genrsa -out ca-key.pem 2048

openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

cat > openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${HOST_IP}
IP.2 = 127.0.0.1
EOF

openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf

openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

groupadd kube_etcd
usermod -a -G kube_etcd etcd
SERVER_KEY=$cert_dir/apiserver-key.pem
chmod 550 "${cert_dir}"
chown -R etcd:kube_etcd "${cert_dir}"
chmod 440 $SERVER_KEY

export ETCD_DISCOVERY=$(curl -w "\n" 'https://discovery.etcd.io/new?size=1')

export ETCD_NAME=${HOST_IP}
export ETCD_DATA_DIR=/var/lib/etcd/default.etcd
export ETCD_LISTEN_CLIENT_URLS=https://${HOST_IP}:2379
export ETCD_LISTEN_PEER_URLS=https://${HOST_IP}:2380

export ETCD_ADVERTISE_CLIENT_URLS=https://${HOST_IP}:2379
export ETCD_INITIAL_ADVERTISE_PEER_URLS=https://${HOST_IP}:2380
#ETCD_DISCOVERY=${ETCD_DISCOVERY}
export ETCD_TRUSTED_CA_FILE=${cert_dir}/ca.pem
export ETCD_CERT_FILE=${cert_dir}/apiserver.pem
export ETCD_KEY_FILE=${cert_dir}/apiserver-key.pem
export ETCD_PEER_TRUSTED_CA_FILE=${cert_dir}/ca.pem
export ETCD_PEER_CERT_FILE=${cert_dir}/apiserver.pem
export ETCD_PEER_KEY_FILE=${cert_dir}/apiserver-key.pem


/usr/bin/etcd
