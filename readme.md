# 0.许可
```
遵循MIT开源许可
```

# 1.部署
## 1.1 配置信任
```
#生成公钥
ssh-keygen
#上传公钥到要同步数据的主机
cd ~/.ssh; ssh-copy-id -i ./id_rsa.pub remote-host
```

## 1.2 定时同步文件
```
crontab -e
sudo systemctl restart corn.service
```
