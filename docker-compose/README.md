# Configuration files for deploying prometheus in a docker environemnt using docker-compose

I used this project: https://github.com/vegasbrianc/prometheus.git

and started the stack with my version of docker-stack.yml and prometheus.yml

```
[root@docker01 prometheus]# /usr/local/bin/docker-compose -f docker-stack.yml up -d
Creating network "prometheus_monitor-net" with the default driver
Creating prometheus_alertmanager_1  ... done
Creating prometheus_cadvisor_1      ... done
Creating prometheus_node-exporter_1 ... done
Creating prometheus_renderer_1      ... done
Creating prometheus_prometheus_1    ... done
Creating prometheus_grafana_1       ... done
```
