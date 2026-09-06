(function () {
  "use strict";

  function element(name, className, text) {
    var node = document.createElement(name);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }

  function link(href, text, className) {
    var node = element("a", className, text);
    node.href = href;
    return node;
  }

  function addReferenceIndexIntroduction() {
    var page = document.querySelector(".template-reference-index");
    var header = page && page.querySelector("main#main .page-header");
    if (!header || page.querySelector(".fs-reference-intro")) return;

    var intro = element("div", "fs-reference-intro");
    var copy = element(
      "p",
      null,
      "Functions are grouped by the work they help you do. Select a function for its usage, arguments, return value and runnable examples."
    );
    var catalogue = link(
      "../articles/options.html",
      "Compare all function arguments",
      "fs-reference-intro-link"
    );
    intro.appendChild(copy);
    intro.appendChild(catalogue);
    header.insertAdjacentElement("afterend", intro);
  }

  function topicPath(href) {
    return new URL(href, window.location.href).pathname;
  }

  function uniqueLinks(nodes) {
    var seen = new Set();
    return Array.prototype.filter.call(nodes, function (node) {
      var path = topicPath(node.getAttribute("href"));
      if (seen.has(path)) return false;
      seen.add(path);
      return true;
    });
  }

  function addCrumb(list, href, text, current) {
    var item = element("li", "fs-breadcrumb-item");
    if (current) {
      item.textContent = text;
      item.setAttribute("aria-current", "page");
    } else {
      item.appendChild(link(href, text));
    }
    list.appendChild(item);
    return item;
  }

  function addBreadcrumb(main, items) {
    if (!main || main.querySelector(".fs-breadcrumb")) return null;
    var header = main.querySelector(".page-header");
    if (!header) return null;

    var breadcrumb = element("nav", "fs-breadcrumb");
    breadcrumb.setAttribute("aria-label", "Breadcrumb");
    var crumbs = element("ol", "fs-breadcrumb-list");
    items.forEach(function (item) {
      addCrumb(crumbs, item.href, item.text, Boolean(item.current));
    });
    breadcrumb.appendChild(crumbs);
    header.insertAdjacentElement("beforebegin", breadcrumb);
    return { breadcrumb: breadcrumb, crumbs: crumbs, header: header };
  }

  function addReturnLink(header, href, text) {
    if (!header || header.parentElement.querySelector(".fs-page-return")) return;
    header.insertAdjacentElement(
      "beforebegin",
      link(href, "\u2190 " + text, "fs-page-return")
    );
  }

  function addTopicRail(main, label, allHref, allText) {
    var rail = element("nav", "fs-topic-nav");
    rail.setAttribute("aria-label", label);
    var all = link(allHref, allText, "fs-topic-nav-all");
    rail.appendChild(all);
    main.appendChild(rail);
    return { rail: rail, all: all };
  }

  function addRailLink(rail, item, position) {
    if (!item) return;
    var label = position === "previous" ? "Previous: " : "Next: ";
    var node = link(
      item.href,
      label + item.text,
      "fs-topic-nav-" + position
    );
    node.rel = position === "previous" ? "prev" : "next";
    if (position === "previous") {
      rail.insertBefore(node, rail.firstChild);
    } else {
      rail.appendChild(node);
    }
  }

  function guideLinks() {
    var nodes = document.querySelectorAll(
      "#dropdown-guides + .dropdown-menu a[href*='articles/'], " +
      "#dropdown-guides + .dropdown-menu a[href^='../articles/']"
    );
    return uniqueLinks(nodes).filter(function (node) {
      return !topicPath(node.href).endsWith("/articles/index.html");
    }).map(function (node) {
      return {
        href: node.href,
        path: topicPath(node.href),
        text: node.textContent.trim()
      };
    });
  }

  function addGuideNavigation() {
    var page = document.querySelector(".template-article");
    var main = page && page.querySelector("main#main");
    var header = main && main.querySelector(".page-header");
    if (!header || main.querySelector(".fs-guide-navigation")) return;

    var heading = header.querySelector("h1");
    var title = heading ? heading.textContent.trim() : document.title.split("\u2022")[0].trim();
    var context = addBreadcrumb(main, [
      { href: "../index.html", text: "Home" },
      { href: "index.html", text: "Guides" },
      { text: title, current: true }
    ]);
    addReturnLink(context && context.header, "index.html", "All guides");

    var navigation = addTopicRail(
      main,
      "Guide navigation",
      "index.html",
      "All guides"
    );
    navigation.rail.classList.add("fs-guide-navigation");

    var guides = guideLinks();
    var currentPath = window.location.pathname;
    var currentIndex = guides.findIndex(function (item) {
      return item.path === currentPath;
    });
    if (currentIndex < 0) return;
    addRailLink(navigation.rail, guides[currentIndex - 1], "previous");
    addRailLink(navigation.rail, guides[currentIndex + 1], "next");
  }

  function addIndexBreadcrumbs() {
    var reference = document.querySelector(".template-reference-index main#main");
    addBreadcrumb(reference, [
      { href: "../index.html", text: "Home" },
      { text: "Reference", current: true }
    ]);

    var articles = document.querySelector(".template-article-index main#main");
    var articlesHeading = articles && articles.querySelector(".page-header h1");
    if (articlesHeading && articlesHeading.textContent.trim() === "Articles") {
      articlesHeading.textContent = "Guides";
      document.title = document.title.replace(/^Articles\b/, "Guides");
    }
    addBreadcrumb(articles, [
      { href: "../index.html", text: "Home" },
      { text: "Guides", current: true }
    ]);
  }

  async function addReferenceTopicNavigation() {
    var page = document.querySelector(".template-reference-topic");
    var main = page && page.querySelector("main#main");
    var header = main && main.querySelector(".page-header");
    if (!header || main.querySelector(".fs-breadcrumb")) return;

    var sourceName = header.querySelector(".name code");
    var topic = sourceName
      ? sourceName.textContent.trim().replace(/\.Rd$/, "()")
      : header.querySelector("h1").textContent.trim();

    var context = addBreadcrumb(main, [
      { href: "../index.html", text: "Home" },
      { href: "index.html", text: "Reference" },
      { text: topic, current: true }
    ]);
    var crumbs = context.crumbs;
    var currentCrumb = crumbs.lastElementChild;
    addReturnLink(context.header, "index.html", "All functions");

    var navigation = addTopicRail(
      main,
      "Function reference navigation",
      "index.html",
      "All functions"
    );
    var topicNav = navigation.rail;
    var allFunctions = navigation.all;

    try {
      var response = await fetch("index.html", { credentials: "same-origin" });
      if (!response.ok) return;
      var html = await response.text();
      var index = new DOMParser().parseFromString(html, "text/html");
      var links = Array.prototype.slice.call(
        index.querySelectorAll("main#main dl dt a[href]")
      );
      var currentPath = window.location.pathname;
      var currentLink = links.find(function (node) {
        return topicPath(node.getAttribute("href")) === currentPath;
      });
      if (!currentLink) return;

      topic = currentLink.textContent.trim();
      currentCrumb.textContent = topic;
      currentCrumb.setAttribute("aria-current", "page");

      var functionSection = currentLink.closest(".section.level2");
      var headingSection = functionSection;
      while (headingSection && !headingSection.querySelector("h2")) {
        headingSection = headingSection.previousElementSibling;
      }
      var groupHeading = headingSection && headingSection.querySelector("h2");
      if (groupHeading) {
        var groupItem = element("li", "fs-breadcrumb-item");
        groupItem.appendChild(
          link("index.html#" + groupHeading.id, groupHeading.textContent.trim())
        );
        crumbs.insertBefore(groupItem, currentCrumb);
      }

      var referenceLinks = uniqueLinks(index.querySelectorAll("main#main dl dt a[href]"));
      var currentIndex = referenceLinks.findIndex(function (node) {
        return topicPath(node.getAttribute("href")) === currentPath;
      });

      if (currentIndex > 0) {
        addRailLink(topicNav, {
          href: referenceLinks[currentIndex - 1].getAttribute("href"),
          text: referenceLinks[currentIndex - 1].textContent.trim()
        }, "previous");
      }
      if (currentIndex >= 0 && currentIndex < referenceLinks.length - 1) {
        addRailLink(topicNav, {
          href: referenceLinks[currentIndex + 1].getAttribute("href"),
          text: referenceLinks[currentIndex + 1].textContent.trim()
        }, "next");
      }
    } catch (error) {
      // The Home, Reference and All functions links remain usable when the
      // index cannot be read, for example when HTML is opened from disk.
    }
  }

  function initialise() {
    addReferenceIndexIntroduction();
    addIndexBreadcrumbs();
    addGuideNavigation();
    addReferenceTopicNavigation();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialise);
  } else {
    initialise();
  }
})();
