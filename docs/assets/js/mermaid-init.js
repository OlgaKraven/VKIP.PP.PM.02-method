document$.subscribe(function () {
  if (window.mermaid) {
    window.mermaid.initialize({
      startOnLoad: true,
      theme: "default",
      securityLevel: "loose"
    });
    window.mermaid.run();
  }
});
