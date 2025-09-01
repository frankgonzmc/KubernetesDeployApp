Flujo del Proyecto en Minikube ... Done
1. Preparación del entorno  .. Done

Verificar que tienes Minikube y kubectl funcionando.  .. Done
Crear un Namespace exclusivo para el proyecto (mi-app). Esto mantendrá todos los recursos aislados. .. Done

👉 Razón: trabajar con Namespaces te da la mentalidad de entornos separados (como dev/prod). .. Done

2. Configurar la base de datos ..done

Crear un PersistentVolumeClaim (PVC) para almacenar datos. .. done

Crear un Deployment de la base de datos (MySQL). .. done

Exponerlo con un Service tipo ClusterIP para que sea accesible solo dentro del cluster. ..done

👉 Razón: la base de datos debe tener almacenamiento persistente y no debe ser expuesta públicamente. ..done

3. Crear ConfigMaps y Secrets .. done

ConfigMap → variables de configuración no sensibles (nombre de la BD, host, etc.). ..done

Secret → credenciales de la base de datos. ..done

👉 Razón: separar configuración y secretos del código para buenas prácticas de seguridad y portabilidad. ..done

4. Configurar el backend

Crear un Deployment para tu aplicación backend (ej. Django, Flask, Node.js). ..done

Enlazar las variables de entorno al ConfigMap y Secret. ..done

Exponerlo internamente con un Service tipo ClusterIP.

👉 Razón: el backend debe poder comunicarse con la DB usando los servicios internos de Kubernetes.

5. Exponer el backend al exterior

Tienes dos caminos:

Opción 1 (más simple): usar un Service tipo NodePort y acceder vía minikube service.

Opción 2 (más realista): instalar un Ingress Controller en Minikube y crear un recurso Ingress para exponer la app en una URL (http://miapp.local).

👉 Razón: NodePort es fácil para pruebas, Ingress se usa en entornos de producción.

6. Probar la aplicación

Crear una base de datos en el contenedor DB si es necesario (ejecutando un init script o kubectl exec).

Confirmar conectividad:

Backend → DB ✅

Cliente (navegador) → Backend ✅

7. Opcionales para mejorar el proyecto

Agregar un frontend (React/Vue) como otro Deployment.

Usar un HorizontalPodAutoscaler (HPA) para escalar el backend según la carga.

Añadir livenessProbe y readinessProbe al backend.

Simular un fallo de pod para ver cómo el Deployment mantiene disponibilidad.

🧭 Resumen del flujo

Preparar Minikube y Namespace.

Desplegar base de datos (Deployment + PVC + Service).

ConfigMaps y Secrets.

Desplegar backend (Deployment + Service).

Exponer backend al exterior (NodePort o Ingress).

Probar funcionamiento end-to-end.

Extras opcionales.


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

### 8. Service (Cluster IP) para el deploy Backend_
Según la arquitectura, nuestra aplicación es una API Rest, la aplicación ya hace conexión con la base de datos por medio del service ClusterIP, pero ahora se necesita que el backend tambipen se exponga dentro del cluster para ser consumido por el deployment del Frontend que se mostrará mas adelante. Es por eso que tambien con un Service ClusterIP podemos hacer esto. El service está en "services/clusterip_deployment_backend.yaml".


