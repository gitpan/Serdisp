#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <serdisplib/serdisp.h>

#include <gd.h>
#include <gdfontt.h>
#include <gdfonts.h>
#include <gdfontmb.h>
#include <gdfontl.h>
#include <gdfontg.h>

#include "ppport.h"

typedef struct {

   serdisp_CONN_t	*	sdcd;
	serdisp_t		*	dd;
	int					invers;
	char				*	connection;
	char				*	display;

} Serdisp;

Serdisp*
new_serdisp(char *connection, char *display)
{
    Serdisp *serdisp	= malloc(sizeof(Serdisp));
    serdisp->connection	= savepv(connection);
    serdisp->display		= savepv(display);
    serdisp->invers		= 0;
    return serdisp;
}

int
init(Serdisp *serdisp)
{
	serdisp->sdcd = SDCONN_open(serdisp->connection);

	if (serdisp->sdcd == (serdisp_CONN_t*)0)
	{
		Perl_croak(aTHX_ "Error opening %s, additional info: %s", serdisp->connection, sd_geterrormsg());
	}

	/* opening and initialising the display */
	serdisp->dd = serdisp_init(serdisp->sdcd, serdisp->display, "");

	if (!serdisp->dd)
	{
		SDCONN_close(serdisp->sdcd);
		Perl_croak(aTHX_ "Error opening display %s, additional info: %s", serdisp->display, sd_geterrormsg());
	}
	return 1;
}

int
width(Serdisp *serdisp)
{
	return serdisp_getwidth(serdisp->dd);
}

int
height(Serdisp *serdisp)
{
	return serdisp_getheight(serdisp->dd);
}

int
draw(Serdisp *serdisp)
{
	/* turning on backlight */
	serdisp_setoption(serdisp->dd, "BACKLIGHT", SD_OPTION_YES);

	/* clearing the display */
	serdisp_clear(serdisp->dd);

	int i;

	/* draw a border (only internal display buffer is affected!!) */
	for (i = 0; i < serdisp_getwidth(serdisp->dd); i++) {
		serdisp_setcolour(serdisp->dd, i, 0, SD_COL_BLACK);
		serdisp_setcolour(serdisp->dd, i, serdisp_getheight(serdisp->dd)-1, SD_COL_BLACK);
	}
	for (i = 1; i < serdisp_getheight(serdisp->dd)-1; i++) {
		serdisp_setcolour(serdisp->dd, 0, i, SD_COL_BLACK);
		serdisp_setcolour(serdisp->dd, serdisp_getwidth(serdisp->dd)-1, i, SD_COL_BLACK);
	}

	/* commit changes -> update the display using the internal display buffer */
	serdisp_update(serdisp->dd);

	return 1;
}

#define min(a,b) ((a)<(b))?(a):(b)
#define GET_COLOR_VALUE(d)        ((d)->invers ? SD_COL_WHITE : SD_COL_BLACK)
#define GET_COLOR_VALUE_INVERS(d) ((d)->invers ? SD_COL_BLACK : SD_COL_WHITE)

void
copyGD(Serdisp *serdisp, gdImagePtr image)
{
	int i,j;

	int max_x = min(gdImageSX(image), serdisp_getwidth(serdisp->dd));
	int max_y = min(gdImageSY(image), serdisp_getheight(serdisp->dd));

	int x,y;

	for (y = 0; y < max_y; y++)
	{
		for (x = 0; x < max_x; x++)
		{
			int c = gdImageGetPixel(image, x, y);

	      serdisp_setcolour(
	       	serdisp->dd,
	       	x, y,
	       	c
	       	?	GET_COLOR_VALUE(serdisp)
	       	:	GET_COLOR_VALUE_INVERS(serdisp)
	       );
		}
	}
	serdisp_update(serdisp->dd);
}

void
clear(Serdisp *serdisp)
{
	serdisp_clear(serdisp->dd);
}

int
update(Serdisp *serdisp)
{
	serdisp_update(serdisp->dd);
}

void
delete_display(Serdisp *serdisp) {

	/* shutdown display and release device*/
	serdisp_quit(serdisp->dd);
	free(serdisp);
}

MODULE = Serdisp		PACKAGE = Serdisp

Serdisp *
new (CLASS, connection, display)
		char *CLASS
		char *connection
		char *display
	CODE:
		RETVAL = new_serdisp(connection, display);
	OUTPUT:
		RETVAL

int
init (serdisp)
    Serdisp*   serdisp

int
width (serdisp)
    Serdisp*   serdisp

int
height (serdisp)
    Serdisp*   serdisp

int
draw (serdisp)
	Serdisp*   serdisp

void
copyGD(serdisp, image)
	Serdisp*		serdisp
	gdImagePtr		image

int
update(serdisp)
    Serdisp*   serdisp

void
clear(serdisp)
    Serdisp*   serdisp

void
DESTROY(serdisp)
    Serdisp *serdisp
  CODE:
    delete_display(serdisp); /* deallocate that object */
