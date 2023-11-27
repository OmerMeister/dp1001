# Use an official base image as a starting point
FROM node:15-alpine3.13

# Set the working directory inside the container
WORKDIR /app

# copy dependencies files
COPY package*.json ./

# install dependencies
RUN npm install

# copy rest of the app
COPY . .

# expose ports
EXPOSE 8080

# random encryption key for jwt (encrypts passwords in the db)
ENV SECRET_KEY=eFnU1qPP.5zlRfHUx71Wao^4+txWS212YVytn6X8gKtMyGT4waG>~hY8gk%ZJy3:44GDR7uUTIZnbQPWx0m8PKn9A!Vf?0s3>+CMvx5w9BYe-rh9j5c6%0t6XrRW4It?NbzjCPZ^~nkAW!qBgua!WH7ZAw.U:m2++%>s63JXNiQPMMyXbAaK*0c47@5!+<uWk0NBY&n9fxjfxX4c~!6W^EwD&RN~5o+s4xu1N2IL2B!SUOR?Q<f0j&dsaY^KlAXZ
# port for contacting the backend server
ENV PORT=8080
# connection string for the containerized mongodb
ENV DATABASE_URL=roseflix-mongodb://meister:lemon123%21%40%23@roseflix-mongodb-cont:27017
# connection string for the cloud mongodb atlas, don't forget to edit "REPLACE_WITH_MY_PASSWORD" and "REPLACE_WITH_MY_USERNAME"
#ENV DATABASE_URL=mongodb+srv://REPLACE_WITH_MY_USERNAME:REPLACE_WITH_MY_PASSWORD@cluster0.tlpupkp.mongodb.net/?retryWrites=true&w=majority

# run project
CMD npm run prod