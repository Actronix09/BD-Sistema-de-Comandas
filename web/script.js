/* ===========================================================
   Visor de diagramas.

   Los diagramas del proyecto son muy anchos (el EER mide 3672
   píxeles de ancho), así que en la página se muestran reducidos
   dentro de un contenedor con desplazamiento lateral. Este guion
   abre la versión grande en una superposición que se recorre
   arrastrando con el ratón o con el dedo.
   =========================================================== */

(function () {
  'use strict';

  var visor = document.getElementById('visor');
  var lienzo = document.getElementById('visor-lienzo');
  var imagen = document.getElementById('visor-imagen');
  var cerrar = document.getElementById('visor-cerrar');

  if (!visor || !lienzo || !imagen || !cerrar) return;

  /* --- Abrir y cerrar ------------------------------------- */

  function abrir(ruta, descripcion, natural) {
    imagen.src = ruta;
    imagen.alt = descripcion || 'Diagrama en tamaño completo';
    lienzo.classList.toggle('natural', natural);
    lienzo.scrollLeft = 0;
    lienzo.scrollTop = 0;
    visor.hidden = false;
    document.body.classList.add('visor-abierto');
    cerrar.focus();
  }

  function cerrarVisor() {
    visor.hidden = true;
    document.body.classList.remove('visor-abierto');
    imagen.src = '';
  }

  /* Cualquier imagen con data-completa y cualquier botón con
     data-abrir disparan el visor. Así se pueden agregar más
     diagramas sin tocar este archivo. Con data-natural el
     diagrama se abre a su tamaño real en vez de a la altura de
     la pantalla, para los que no son tan anchos. */

  document.querySelectorAll('img[data-completa]').forEach(function (img) {
    img.addEventListener('click', function () {
      abrir(img.dataset.completa, img.alt, 'natural' in img.dataset);
    });
  });

  document.querySelectorAll('[data-abrir]').forEach(function (boton) {
    boton.addEventListener('click', function () {
      abrir(boton.dataset.abrir, undefined, 'natural' in boton.dataset);
    });
  });

  cerrar.addEventListener('click', cerrarVisor);

  document.addEventListener('keydown', function (evento) {
    if (evento.key === 'Escape' && !visor.hidden) cerrarVisor();
  });

  /* --- Arrastrar para recorrer ---------------------------- */

  var arrastrando = false;
  var inicioX = 0;
  var inicioY = 0;
  var desplazamientoX = 0;
  var desplazamientoY = 0;

  lienzo.addEventListener('pointerdown', function (evento) {
    arrastrando = true;
    inicioX = evento.clientX;
    inicioY = evento.clientY;
    desplazamientoX = lienzo.scrollLeft;
    desplazamientoY = lienzo.scrollTop;
    lienzo.classList.add('arrastrando');
    lienzo.setPointerCapture(evento.pointerId);
  });

  lienzo.addEventListener('pointermove', function (evento) {
    if (!arrastrando) return;
    lienzo.scrollLeft = desplazamientoX - (evento.clientX - inicioX);
    lienzo.scrollTop = desplazamientoY - (evento.clientY - inicioY);
  });

  function soltar() {
    arrastrando = false;
    lienzo.classList.remove('arrastrando');
  }

  lienzo.addEventListener('pointerup', soltar);
  lienzo.addEventListener('pointercancel', soltar);

  /* La imagen nace arrastrable por defecto y eso pelea con el
     recorrido: se desactiva. */
  imagen.addEventListener('dragstart', function (evento) {
    evento.preventDefault();
  });
})();
