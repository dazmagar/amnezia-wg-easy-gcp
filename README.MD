# Amnezia VPN
https://amnezia.org/en

# Amnezia WG Easy
https://github.com/w0rng/amnezia-wg-easy

# Hints
In case of WG updates
``` bash
terraform apply -replace="module.provisioner.null_resource.install_docker"
terraform apply -replace="module.provisioner.null_resource.clone_repository"
terraform apply -replace="module.provisioner.null_resource.build_amnezia_image"
terraform apply -replace="module.provisioner.null_resource.copy_wireguard_configs" # to run this command set variable `enable_wg_configs` = `true`
terraform apply -replace="module.provisioner.null_resource.run_amnezia_docker_container"
```
