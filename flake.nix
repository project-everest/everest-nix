{
  inputs = { projects.url = "./projects"; };
  outputs = { self, projects }: projects;
}
