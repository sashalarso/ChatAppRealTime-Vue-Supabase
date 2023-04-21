# Utilisez une image de Node.js comme base
FROM node:latest

# Créez un répertoire de travail dans l'image
WORKDIR /app

# Copiez tous les fichiers de votre application dans l'image
COPY . .

# Installez les dépendances de votre application
RUN npm install

# Exposez le port 8080 sur lequel votre application sera accessible
EXPOSE 9000

# Lancez votre application en mode développement en utilisant la commande "quasar dev"
CMD ["npm", "run", "dev"]
