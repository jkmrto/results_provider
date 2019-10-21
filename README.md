
# ResultsProvider

This application provides football results exposig a public HTTP API. These results have to be requested by league and season pairs and it supports two format: *json* and *protobuffer*.

1. [How to use the HTTP API ](#httpapi)
2. [Application Overview](#overview)
3. [Development Stup and Useful Commands](#dev)
4. [Protobuffer Messages](#protobuffer)
5. [Docker Compose Setup](#dockercompose)
6. [Kubernetes Setup ](#kubernetes)




<a id="httpapi"></a>

## How to use the HTTP API?

There are 3 differents endpoints that the client can use to interact with the service.

### **GET** **/results-provider/ready**

This endpoint verifies if the results are available.

**Answer**: When results are ready:
  ```
  HTTP Code: 200
  Content Type: "application/json"
  Body: "Service available"
  ```
**Answer**: When results are no  ready:
  ```
  HTTP Code: 503
  Content Type:  "text/plain"
  Body: "Service not available"
  ```

### **GET /results-provider/list**

This endpoints returns a list of season-league tuples if the resuls are ready.

**Answer**: When results are ready:
  ```
  HTTP Code: 200
  Content Type: "application/json"
  Body: {type: "Season and league pairs available", data: [{season, league}] }
  ```
**Answer**: When results are no ready:
  ```
  HTTP Code: 503
  Content Type: "text/plain"
  Body:  "Service not available"
  ```

### **GET /results-provider/:league/:season**

This endpoint returns the results of the matches for the specific league and seson indicated at the url. 

For example for the league "SP1" and season "201617" the associated request will be:
```
GET /results-provider/SP1/201617
```
For a list of the available leagues and seasons you can try a call to the endpoint *GET /results-provider/list*.  

This endpoint supports to output the data in *json* and *protobbufer* format. In order to indicate the format we need to add a format query parameter to url. So there are these possibilities:

#### **GET** /results-provider/:league/:season

If no format is specified by default the data will be coded as json, so it will be the same as calling **GET** /results-provider/:league/:season?format=json.

#### **GET** /results-provider/:league/:season?format=json

**Answer**: When results are ready:

  ```
  HTTP Code: 200
  Content Type: "application/json"
  Body: <Message Results at ./protobufs/results.proto coded as Json>
  ```
**Answer**: When results are no ready:
  ```
  HTTP Code: 503
  Content Type: "text/plain"
  Body:  "Service not available"
  ```

#### **GET** /results-provider/:league/:season?format=protobuffer

**Answer**: When results are ready:

  ```
  HTTP Code: 200
  Content Type: "application/protobuf;proto=results"
  Content: <Message Results at ./protobufs/results.proto coded as protobuffer>
  ```
**Answer**: When results are no ready:
  ```
  HTTP Code: 503
  Content Type: "text/plain"
  Content:  Service not available"
  ```

#### **GET** /results-provider/league/season?format=any_wrong_format

In case of specifying a wrong format it will be notified to the client at the answer.

  ```
  HTTP Code: 400
  Content Type: "The format specified <any_wrong_format> is not valid, it should be protobuffer or json"
  Content: <Message Results at ./protobufs/results.proto coded as protobuffer>
  ```
**Answer**: When results are no ready:
  ```
  HTTP Code: 503
  Content Type: "text/plain"
  Content:  Service not available"
  ```

#### **ANY** /any

Any other method with any other URL will get this answer:

```
HTTP Code: 404
Content Type: "text/plain"
Content:  "What are you looking for?"
```



<a id="overview"></a>
## Application Overview

This application has two main components one is the [HTTP endpoint](./lib/results_provider/web/endpoint.ex) that will be in charge of handling the HTTP requests and the other is the cache ([ets](http://erlang.org/doc/man/ets.html)) of the football results with one [handler](./lib/results_provider/cache/handler.ex) associated to it.

 
At the [application startup](./lib/results_provider.ex) both the HTTP listener and the handler of the cache will be started. This [cache handler](./lib/results_provider/cache/handler.ex) plays a capital role in the service since it will be in charge of loading the `Data.csv` file to the cache, if this fails no data will be availabe so there wont be service. 

The [cache handler](./lib/results_provider/cache/handler.ex) implements a GenServer and will keep in his state a list of available league-season pairs and a boolean indicating if the service is ready or not, that is if the *Data.csv* has been loaded. It will also create the results cache at start.

### Cache :results_table Overview

The main benefit of using a cache is that the response time will be faster that directly reading the results from the `Data.csv` each time it gets a request.  At this application there is not a high load of data so maybe we could store the data directly on the GenServer state, but if we think in larger amounts of data it is much more recomendable to keep it in cache. Cache also allows concurrent read so it is another favor point. 

It is important to note that the ready boolean at cache handler will be settled to true once the data is correctly loaded, so if a request comes before the data gets loaded this boolean will be consulted and HTTP code 503 of unavability will be sent as answer to the client.

If for some reason the cache crashed at some point, the cache handler will also crashed (since they are linked), being restarted by the application supervisor and loading again all the data.

The data will be stored at the cache at this format:
```
{league, season} -> ResultsProvider.Definitions.MatchResult
```
As the cache table is created with *:bag* mode it allows to register various rows with same keys, in our case the key is the tuple {league, season}. So we just need to look for the league and season keys to get their respective results.

Another possible approach will be to directly associating to each {league, season} key only one [Results](./protobufs/result.proto) with all the [Match Result](./protobufs/match_results.proto) of this season league.

```
{league, season} -> ResultsProvider.Definitions.Results
```
So we can get the data even faster with this. Anyway I have prefered to keep the other format because it is quite more versatil and will allow another kinds of requests. (Like it allows to mix all the season of a leagues and so on).


<a id="dev"></a>
## Development Setup and Commands


### Language Runtime Version Control

This project uses [asdf](https://github.com/asdf-vm/asdf) to manage the version of Elixir and Erlang used during the development of the application.

This project was developed on Elxir 1.7.4  and Erlang 21.1, you can verify this at the [.tool-versions](.tool-versions) file.

Download and compile dependencies

``` bash
mix deps.get
mis deps.compile
```

Compile application
```
mix compile
```

Run on interactive mode
```
iex -S mix
```

Create release
``` bash
mix release
```

### Recompile Protobuff files

```
rm ./_build/dev/exprotobuf
mix deps.compile exprotobuff
```


### Docker Commands

* Build
```
docker build -t results_provider
```
* Build without using cache layers
```
docker build -t results_provider --no-cache
```
* RUN exposing the port 4000
``` Run
docker run --name results_provider -p 4005:4000 -d results_provider
```
* Get into the running container

``` Bash
docker exec -i -t results_provider bash
```

<a id="protobuffer"></a>
## Protobuffer Messages

In the folder `./protobufs` have been stored the definitions on the messages used to encode the data [ProtoBuffer](https://developers.google.com/protocol-buffers/) format. At this version there are available three different messages, **PeriodResult**, **MatchResult**, **Results**.

We load this messages definitions at the module  [ResultsProvider.Definitions](./lib/results_provider/definitions.ex). Each message will be load as a module with the name `ResultsProvider.Definitions.{message_name}`, like `ResultsProvider.Definitions.MatchResult` for MatchResult message.

At the module [ResultsProvider.Definitions.Jason](./lib/results/provider_defintions.ex) we derive the [Jason.Encoder](https://github.com/michalmuskala/jason) on all the modules generated by the messages in order to allow the `Jason.encode(module)` funcionality over these structs.

<a id="dockercompose"></a>
##  Docker Compose Setup

### Docker Compose File

The proposed *docker-compose.yml* is this:

```yml
version: '3'

services:
  lb:
    image: haproxy:1.7
    ports:
      - "90:80"
    volumes:
      - ./haproxy:/usr/local/etc/haproxy
  app1:
      image: results_provider:latest
  app2:
      image: results_provider:latest
  app3:
      image: results_provider:latest
      
```
At this file we have defined 4 services: one service is the load balancer `lb`, while the other three services `app1`, `app2`, `app3` are some instances of our `results_provider` application.

####  Load Balancer Service
The `lb` service is configured with
* The image to be instantiated: 
```yml
image: `haproxy:1.7`
```
* The external port is the 90 while the haproxy server will be binded to the port 80 internally: 
```yml
ports:
  - "90:80"
```
* Load the HAProxy configuration from a the local folder `./haproxy`. This will load this host folder to the folder  `/usr/local/etc/haproxy` that is where HA Proxy server will read his configuration.
```yml
volumes:
  - ./haproxy:/usr/local/etc/haproxy
```
The content of this will be exposed later at [HAProxy Configuration](#haproxyconfiguration) to it so:

####  Application Services 

Three instances of the *results_provider* application, the only difference is the service name that will allow to specify each service from the load balancer at `haproxy.cfg`.
```  yml
app1:
  image: results_provider:latest
app2:
  image: results_provider:latest
app3:
  image: results_provider:latest
```

###  HAProxy Configuration

The proposed `haproxy.cfg` file is this one:
```cfg
defaults
  mode http                               
  timeout connect 5000ms                   
  timeout client 50000ms                   
  timeout server 50000ms

frontend haproxynode
    bind *:80
    mode http
    default_backend backendnodes

backend backendnodes
    balance roundrobin
    option httpchk GET /results-provider/ready HTTP/1.0
    server node1 app1:4000 check
    server node2 app2:4000 check
    server node3 app3:4000 check
```

On the default section it is defined that the server should work for http requests and some timeout form the proxy server.

On the frontend section it is defined how requests should be forwarded to backend. We have defined that HTTP requests coming from any interface at port 80 should be forwarded to the backend called bacendnodes.

On the backend section is is defined to use roundrobin algorithm to load balance. It has been added the line `option httpchk GET /results-provider/ready HTTP/1.0` to make a status check to the servers in order to verify that the cache data is already loaded.

Finally the three servers are specified using the given service name in docker-compose deplyment file. This service name is interpreted at docker-compose level as the hostname of this dockers, so we can comunicate with them using it.

### Aditional Comments

A good point of this aproximation is that only the load balancer is able to comunicate to the docker (since the application instances dont expose any port), so the application dockers are isolated from external requests.

<a id="kubernetes"></a>
## Kubernetes Setup

The  deployment files that can be found at *./kubernetes/* folder  have been developed and executed in a [Minikube](https://kubernetes.io/docs/setup/minikube/) environment which allows us to run a single-node Kubernetes cluster locally. The installation of *Minikube* is really easy and it is described at this [link](https://kubernetes.io/docs/tasks/tools/install-minikube/).

Although the deployment in *Minikube* is really similar to a real cloud cluster, there are some differences that will be commented further.

### Minikube setup

Let's start the *Minikube* cluster. This will set up a virtual machine with a Kubernetes cluster working inside.

```Bash
minikube start
```

Let's enable **Ingress** which will be the entrypoint for our cluster. It works like load balancer (like nginx) with some set of rules to redirect the entry traffic to the proper service. 
```Bash
minikube addons enable ingress
```


### Setting up application image on minikube

Here there are some issues since we are working with *minikube* and a little development environment. Normally, when using *Kubernetes* we will publish the images at a [docker-registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/), but in our case to avoid having to launch an external *docker-registry* we will just make available the container image of the application available in the kubernetes docker environment.

We need to switch for our local docker-env to the docker-env of *minikube*. It is important to note that they are different scopes so building the image in our local docker-env will not make available the image at the minikube docker.env. This allows to switch the scope:
```Bash 
eval $(minikube docker-env)
```
We can see that effectively we have switch the *docker-env* through ```docker images``` command since the images available are components of minikube.

![Drag Racing](./doc/kubernetes/docker-images.png)


Let's build the docker image of the application. 
```
docker build -t results_provider .  --no-cache
```

This will make the image of our application available to the minikube docker environment.

### Deploying the Pod


Let's deploy the application using the deployment file. This will launch a pod with only one container called *results-provider*.

```
kubectl create  -f kubernetes/results_provider_app.yaml
```

We should not at this file this:
* The name assigned to the app is *results-provider* so this will be named that the service will look for.

* Three replicas will be launched since ```replicas: 3```  have been settled at spec.

* The port at our application should be listening should be the same that the one indicated at   ``` containerPort: 4000``` 


The differences for a real kubernetes cluster are:

* The line `imagePullPolicy: Never ` should be deleted  or settled to `imagePullPolicy: Always ` since by default we would like to pull the latest image from the registry.
* The container image instead of being `results_provider` should be somehing like `<docker-registry>\results_provider` where `<docker-registry>` is the host direction of the registry.


We can verify the application is running through ``` kubectl get pods```. Three running pods will be shown each one with a name beginning with the name of the application followed by some random deployment identification.


![Drag Racing](./doc/kubernetes/kubectl-get-pods.png)

We can verify the web service is runnig (inside of the pod, not outside of the cluster) accesing to the bash of the pod and making a curl request like this.
Acessing to the bash of one our replica pods:
```
kubectl exec -it results-provider-6476dcb987-m68bq bash
```
Installing `curl` and making a simple ready request:
``` bash
root@results-provider-6476dcb987-m68bq: apt-get install curl
root@results-provider-6476dcb987-m68bq: curl localhost:4000/results-provider/ready
{"status":"Available"}
```

###  6.4. <a name='DeployingtheService'></a>Deploying the Service

Let's deploy the service. This will balance the load among the 3 replicas of the application that we have previously launched. The selected service type is ```NodePort```. This will allow us to make the application reachable from outside through the ingress.

```
kubectl apply -f kubernetes/results_provider_service.yaml
```

It is important to note that the aplication selector should be settled to application previously created.
``` yaml
selector:
    app: results-provider
```



We can verify the service is running through ```kubectl get services```.

![Drag Racing](./doc/kubernetes/kubectl-get-services.png)

Again we can verify the service running using the same strategy of accessing to one of the pods and sending a http request, but in this case instead that to ```localhost:4000/results-provider/ready``` we should try to ```results-provider:4000/results-provider/ready```, so we will be connected to the service.

###  6.5. Running the Ingress

In order to effectively run the Ingress and reach accesibility from the outside to out minikube environment we need to add a hostname to the IP of the minikube VM. This can be done with:
```
echo "$(minikube ip) testhost" | sudo tee -a /etc/hosts
```
This will add a line at ```/etc/hosts``` pointing the host testhos to the IP of minikube cluster.

Let's reconfigure the Ingress:
```
kubectl apply -f kubernetes/ingress.yaml
```
```yaml
.....
spec:
  rules:
  - host: testhost
    http:
      paths:
      - path: /results-provider
        backend:
          serviceName: results-provider
          servicePort: 4000 
  
```
We are indicating at this filter to forward the request to the host ```testhost``` and with the path ```results-provider``` to service named ```results-provider```.

Now we can access to the cluster from the outside like:


``` Bash
curl http://testhost/results-provider/ready
```
Or getting the list of availabe league and season pairs:
```
curl http://testhost/results-provider/list
```


# Who do I talk to?

For any question ask to jkmrto@gmail.com