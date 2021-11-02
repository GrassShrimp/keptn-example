# keptn-example

The demo is base on [Keptn Full Tour on Prometheus](https://tutorials.keptn.sh/tutorials/keptn-full-tour-prometheus-09) for help you build keptn service quickly and run the tutorial with ansible playbook step by step

## Prerequisites

- [terraform](https://www.terraform.io/downloads.html)
- [docker](https://www.docker.com/products/docker-desktop)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [keptn cli](https://keptn.sh/docs/0.6.0/installation/setup-keptn/#install-keptn-cli)

## Usage

initialize terraform module

```bash
$ terraform init
```

create k8s cluster with kind, and install all components - istio, metallb, prometheus, keptn

```
$ terraform apply -auto-approve
```

after the excution done, run the followed command (which display at outputs) for authenticated to keptn server via keptn cli

```
$ keptn auth --endpoint=http://keptn.127.0.0.1.nip.io/api --api-token=$(kubectl get secret keptn-api-token -n keptn -o jsonpath={.data.keptn-api-token} | base64 --decode)
```

and open url "keptn.127.0.0.1.nip.io" in browser for visit ui of keptn

for destroy

```bash
$ terraform destroy -auto-approve
```

for run tutorial, please download example provide by keptn first

```bash
$ git submodule update --remote --init
```

and play the ansible playbook with tutorial step by step

```bash
$ cd tutorial && ansible-playbook main.yaml
```

![keptn](https://github.com/GrassShrimp/keptn-example/blob/master/keptn.png)