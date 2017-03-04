SHORT("[command]")
HELP("shows help of command")
IMMEDIATE(help, 0, 1)
#if CODE
{
  struct commands	*ptr;
  int			width, w;
  const char		*s;

  if (args)
    {
      for (ptr=commands; ptr->name; ptr++)
        if (!strcmp(ptr->name, argv[0]))
          {
            printf("help for: %s %s\n", ptr->name, ptr->help);
            w = 0;
            for (s=ptr->desc; *s; s++)
              {
                if (!w) putchar('\t');
                putchar(*s);
                w = *s!='\n';
              }
            return;
          }
      D->status = 1;
    }

  width = 0;
  for (ptr=commands; ptr->name; ptr++)
    if (width < (w=strlen(ptr->name)))
      width = w;

  printf("Possible commands:\n");
  for (ptr=commands; ptr->name; ptr++)
    {
      printf("  %-*s\t%s\n", width, ptr->name, ptr->help);
    }
}
#endif
