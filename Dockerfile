# تشغيل البرنامج كاملاً (الواجهة + الخادم) على أي استضافة تدعم Docker مثل Railway أو Render أو VPS
FROM node:22-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
# مجلد البيانات الدائمة: قاعدة البيانات المشتركة وشهادات ومستندات الفوترة الإلكترونية والنسخ الاحتياطية
VOLUME ["/app/data"]
CMD ["npx", "tsx", "server.ts"]
