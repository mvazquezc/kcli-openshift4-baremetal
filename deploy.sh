echo export KUBECONFIG=/root/ocp/auth/kubeconfig >> /root/.bashrc
echo export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE={{ openshift_image }} >> /root/.bashrc
echo export OS_CLOUD=metal3-bootstrap >> /root/.bashrc
echo export OS_ENDPOINT=http://172.22.0.2:6385 >> /root/.bashrc
echo export PATH=/usr/local/bin:/root/bin:\$PATH >> /root/.bashrc
echo export LIBVIRT_DEFAULT_URI=qemu+ssh://root@{{ config_host }}/system >> /root/.bashrc
bash /root/network.sh
export PATH=/root/bin:$PATH
mkdir /root/bin
cd /root/bin
bash /root/get_clients.sh
{% if not build %}
bash /root/get_installer.sh
{% endif %}

{% if cache %}
bash /root/cache.sh
{% endif %}

{% if disconnected %}
bash /root/disconnected.sh
{% endif %}

cd /root
if [ -z "$COMMIT_ID" ] ; then
export COMMIT_ID=$(openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
fi
export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
export PRIMARY_IP=$(hostname -I | cut -d" " -f1)
envsubst < metal3-config.yaml.sample > metal3-config.yaml

bash /root/patch_installconfig.sh
{% if virtual %}
bash /root/virtual.sh
{% endif %}

{% if deploy %}
bash deploy_openshift.sh
sed -i "s/metal3-bootstrap/metal3/" /root/.bashrc
sed -i "s/172.22.0.2/172.22.0.3/" /root/.bashrc
{% if imageregistry %}
bash nfs.sh
{% endif %}
{% endif %}