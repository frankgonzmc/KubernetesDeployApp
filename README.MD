
## Documentación

### 1. Namespace:
La infraestructura de la aplicación esta en un entorno aislado (namespace) donde estarán algunos recursos comunicandose entre sí.
El namespace de este proyecto está en el directorio: /namespace que a nivel de todo el cluster se le llamará "my-app".

### 2. Persistent Volume (PV):
Para la base de datos primero se necesita de un lugar donde el pod_bd pueda gestionar los datos.
En este proyecto se usa un persistent volume que mantiene los datos aun si el pod cae, reinicia, etc. Conocido como ciclo de vida del Pod.
En este proyecto el persistent volume esta en el directorio volumes/volume_app.yaml
El PVC esta configirado para entornos local como manual que necesita de una configuración manual de un PVC para servir como puente entre el PV y el Pod.
En entornos reales de producción no es recomendable usar la configuración manual.
Algo que aclarar es el recurso PV no vive dentro de un namespace específico, sino de forma global en el cluster.

### 3. Persistent Volume Claim (PVC):
Como se mencionó en la parte de PV, se necesitará de un puente de conexión entre el Pod_db y el PV, es por eso que se configura un PVC. En este caso se configura en el directorio volumes/pvc.yaml, este objeto si vive dentro de el namespace "my-app" y con las mismas características del PV, así Kubernetes sabe con cuál hacer la conexión.

### 4. Deployment de la Base de Datos:
Un deployment permitirá tener una replica de un Pod que correrá un contenedor con la imagen de MySql. Será necesario configurar algunos parámetros mas, como el lugar donde se guaradarán los datos, es para esto que se crearón el PV y PVC, para conexión solo es necesario especificar cuál es el PVC que usará nuestro Pod como volume. En entornos de Base de Datos tanbién se necesitan de credenciales como el usuario y la contraseña, pero para buenas prácticas de seguridad se usrán otros objetos. Cabe recalcar que un deployment si es un objeto Namespaced, por lo tanto este estará viviendo en nuestro Namespace "my-app".

### 5. ConfigMap y Secrets para el Pod DB:
Como se mencionó anteriormente en el deployment de la base de datos, se necesitará configurar algunos paramétros como credenciales.
Esto se configuró en el deployment de db en "envFrom" que llama a dos recursos: ConfigMap y Secret. El recurso configMap se encuentra en el directorio configMap/config_map_deployment_db.yaml y contiene variables de entorno que son configuración no sensible como el nombre de la db y el usuario.
En el caso de variables sensibles como contraseñas de user y root de la bd se usa los secrets en el directorio secrets/secret_deployment_db.yaml donde los datos estan en base 64.

### 6. Service (ClusterIP) para deployment DB:
En una infraestructura segura, un servicio de base de datos nunca se expone de manera pública, solo algunos recursos como las aplicaciones pueden interactuar con la base de datos, en Kubernetes, dentro del cluster nuestra DB necesitará abrir un puerto de comunicación interna solo dentro del cluster y en este caso en el namespace "my-app", los pods en el mismo namespace puede conectarse con el nombre del service, pero los que no se encuentran en el mismo namespace pero si en el cluster tendrían que usar FQDN (no aplicable en este caso que solo trabajamos dentro de un mismo namespace). El service CLusterIP permite a un pod abrir un puerto interno para comunicación, a través de una VIP (virtual ip) que como se mencionó nadie fuera del cluster podrá comunicarse con este. 

### 7. Deployment del Backend:
Para alojar el backend de la aplicación, usaremos un deployment [/deployments/backend_deployment.yaml] con 2 replicas que levantará 2 Pods, cada uno con un container con la imagen de mi aplicación backend de pruebas que esta escrito con Flask, es una API Rest CRUD básica, que estará en Docker Hub de mi cuenta y será pública. También se le agrega las variables de entorno de la base de datos para que pueda interactuar con esta. Tanto como los secrets y configMaps de la BD también se usarán como variables de entorno, y también el service CLusterIP que permite exponer el deploy de la BD dentro del cluster, con esto nuestro backend puede iniciar la comunicación interna.

### 8. Service (Cluster IP) para el deploy Backend:
Según la arquitectura, nuestra aplicación es una API Rest, la aplicación ya hace conexión con la base de datos por medio del service ClusterIP, pero ahora se necesita que el backend tambipen se exponga dentro del cluster para ser consumido por el deployment del Frontend que se mostrará mas adelante. Es por eso que tambien con un Service ClusterIP podemos hacer esto. El service está en "services/clusterip_deployment_backend.yaml".

### 9. ConfigMap como archivo de configuración NGINX:
Para nuestra arquitectura usamos un servidor proxy, en este caso NGINX, que contendrá los archivos compilados de React, y cualquier usuario que haga una petición a este servicio expuesto se le responderá con los archivos estáticos, si la petición necesita consumir la API del backend, el servidor Proxy va redirigir el tráfico hacia el service ClusterIP del deploy backend a la cual solo este tiene acceso dentro del cluster. La ruta de este archivo es "/configMap/config_map_nginx.yaml"

### 10. Deployment Frontend:
Nestro deployment del frontend contiene una imagen construida de NGINX, donde la aplicación react construida esta en la ruta de archivos estáticos que sirve el servidor Proxy. Y a su vez usa la configuracion anterior (ConfigMap de NGINX) para ser proxy de backend y frontend por medio de un volumen dentro de los Pods. El archivo esta en "/deployments/frontend_deployment.yaml".

### 11. Service NodePort para el Deploy Frontend:
Como ya tenemos un deploy para el frontend sirviendo como servidor proxy, solo faltaría hacer que este sea accesible desde fuera del cluster. Para lograr esto podemos usar el service Node Port para que cualquier usuario pueda interactuar con el servicio. En este caso usamos el puerto 80 de nuestro deploy pero para hacerlo público fuera a nivel de cluster usaremos el puerto 30080. El archivo se encuentra en "/services/nodeport_deployment_frontend.yaml".