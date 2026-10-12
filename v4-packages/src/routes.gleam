/// The full URL selected for an API request. This alias documents its role;
/// it does not validate the address or distinguish it from other strings.
pub type EndpointUrl =
  String

pub const base = "https://cheekycms.fly.dev/"

pub fn all() -> List(#(String, String)) {
  [
    #("api", "api"),
    #("health", "health"),
    #("example", "api/example"),
    #("exampleHomepage", "api/example/singletons/homepage"),
    #("studio", "api/studio"),
    #("studioHomepage", "api/studio/singletons/homepage"),
    #("studioAbout", "api/studio/singletons/about"),
    #("studioProjects", "api/studio/collections/projects"),
    #("studioFeaturedProjects", "api/studio/collections/projects?featured=true"),
    #("studioOrbit", "api/studio/collections/projects/orbit"),
    #("studioFieldwork", "api/studio/collections/projects/fieldwork"),
    #("studioTeam", "api/studio/collections/team"),
    #("studioAvailableTeam", "api/studio/collections/team?available=true"),
    #("studioAda", "api/studio/collections/team/ada"),
    #("studioMilo", "api/studio/collections/team/milo"),
    #("fieldNotes", "api/field-notes"),
    #("fieldNotesProfile", "api/field-notes/singletons/profile"),
    #("fieldNotesDispatches", "api/field-notes/collections/dispatches"),
    #(
      "fieldNotesNewestDispatch",
      "api/field-notes/collections/dispatches?sort=-published&limit=1",
    ),
    #("afterTheRain", "api/field-notes/collections/dispatches/after-the-rain"),
    #("tideTable", "api/field-notes/collections/dispatches/tide-table"),
    #("fieldNotesPlaces", "api/field-notes/collections/places"),
    #("eagleIsland", "api/field-notes/collections/places/eagle-island"),
    #("recipeBook", "api/recipe-book"),
    #("recipeBookAbout", "api/recipe-book/singletons/about"),
    #("recipes", "api/recipe-book/collections/recipes"),
    #(
      "vegetarianRecipes",
      "api/recipe-book/collections/recipes?vegetarian=true",
    ),
    #(
      "quickestVegetarianRecipe",
      "api/recipe-book/collections/recipes?vegetarian=true&sort=minutes&limit=1",
    ),
    #("pantryRecipes", "api/recipe-book/collections/recipes?tags=pantry"),
    #("lemonChickpeas", "api/recipe-book/collections/recipes/lemon-chickpeas"),
    #("tomatoOrzo", "api/recipe-book/collections/recipes/tomato-orzo"),
  ]
}
