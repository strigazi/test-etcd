Test a bug in etcd 3.0.17 in fedora 25.


Build the image:

docker build -t test-etcd .

Run the test:

docker run --rm --env HOST_IP=<YOUR HOST IP HERE> --net host -p 2379 -p 2380 --name etcd test-etcd
