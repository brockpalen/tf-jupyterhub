FROM jupyterhub/jupyterhub:latest

MAINTAINER brockp@umich.edu

RUN pip install oauthenticator
RUN pip install jupyterhub-tmpauthenticator
RUN pip install jupyterhub-dummyauthenticator
RUN pip install 'globus_sdk[jwt]>=1.0.0,<2.0.0'

RUN pip install jupyterhub-kubespawner

WORKDIR /srv/jupyterhub

# See http://jupyterhub-kubespawner.readthedocs.io/en/latest/spawner.html

# generally you don't wnat to use this here but change it in the configmap 

CMD ["jupyterhub","--ConfigurableHTTPProxy.should_start=False","--JupyterHub.spawner_class='kubespawner.KubeSpawner'","--JupyterHub.ip='0.0.0.0'","--JupyterHub.hub_ip='0.0.0.0'","--JupyterHub.cleanup_servers=False","--KubeSpawner.start_timeout=600","--KubeSpawner.singleuser_image_spec='jupyterhub/singleuser:0.8'","--KubeSpawner.singleuser_service_account='default'","--JupyterHub.authenticator_class='dummyauthenticator.DummyAuthenticator'","--KubeSpawner.user_storage_pvc_ensure=True","--JupyterHub.allow_named_servers=True","--KubeSpawner.debug=True"]


