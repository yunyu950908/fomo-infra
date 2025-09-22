===========================================
MongoDB 连接信息
===========================================

集群内部连接：
--------------------------------------
主机: ${release_name}.${namespace}.svc.cluster.local
端口: 27017

外部连接（通过 NodePort）：
-------------------------------------------
主机: NODE_IP
端口: ${external_port}

连接字符串（外部）：
mongodb://${app_user}:${app_password}@NODE_IP:${external_port}/${database}

管理员连接字符串：
mongodb://${root_user}:${root_password}@NODE_IP:${external_port}/admin

凭据信息：
------------
管理员用户: ${root_user}
管理员密码: ${root_password}
数据库: ${database}
应用用户: ${app_user}
应用密码: ${app_password}

CLI 访问：
-----------
# 从集群内连接：
kubectl run -it --rm --restart=Never mongodb-client \
  --image=bitnami/mongodb:${mongodb_version} \
  --namespace=${namespace} \
  -- mongosh mongodb://${app_user}:${app_password}@${release_name}:27017/${database}

# 端口转发进行本地访问：
kubectl port-forward -n ${namespace} svc/${release_name} 27017:27017

# 然后本地连接：
mongosh mongodb://${app_user}:${app_password}@localhost:27017/${database}

应用程序配置示例：
-----------------------------------

Node.js (mongoose):
------------------
const mongoose = require('mongoose');
mongoose.connect('mongodb://${app_user}:${app_password}@${release_name}.${namespace}.svc.cluster.local:27017/${database}');

Python (pymongo):
-----------------
from pymongo import MongoClient
client = MongoClient('mongodb://${app_user}:${app_password}@${release_name}.${namespace}.svc.cluster.local:27017/${database}')

Go (mongo-driver):
------------------
import "go.mongodb.org/mongo-driver/mongo"
import "go.mongodb.org/mongo-driver/mongo/options"

uri := "mongodb://${app_user}:${app_password}@${release_name}.${namespace}.svc.cluster.local:27017/${database}"
client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(uri))