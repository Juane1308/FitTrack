# Servicios del chatbot

El cliente consulta el endpoint autenticado `/api/chat`. El backend incorpora
el perfil del usuario, su objetivo, el lugar de entrenamiento y el catálogo de
ejercicios almacenado en Neon antes de solicitar la recomendación a Gemini.
